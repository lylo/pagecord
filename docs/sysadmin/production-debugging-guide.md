# Production Debugging Guide

A guide for diagnosing production issues on the Hetzner VPS, based on real incident investigation.

## Quick Reference: Common Error Patterns

| Error | Likely Cause |
|-------|--------------|
| `RedisClient::CannotConnectError` to `10.0.1.1` | Private network or Redis service issue |
| `ActiveRecord::DatabaseConnectionError` to `10.0.1.1` | Private network or PostgreSQL service issue |
| Both errors at same timestamp | Infrastructure event (network, systemd reload, updates) |
| `SSL connection has been closed unexpectedly` | OpenSSL was upgraded |
| `terminating connection due to administrator command` | Database was restarted |

## Network Architecture

The server uses Hetzner's private network for database connections:

- **Public IP**: `116.203.45.5` (eth0)
- **Private IP**: `10.0.1.1` (enp7s0) - used by PostgreSQL and Redis
- Private network interface managed by: `hc-net-ifup@enp7s0.service`

## Investigation Steps

### 1. Check Service Status

```bash
# Redis
systemctl status redis
redis-cli ping

# PostgreSQL
systemctl status postgresql
pg_isready -h 10.0.1.1

# All services
systemctl --failed
```

### 2. Check Network Connectivity

```bash
# Is the private network IP reachable?
ping -c 3 10.0.1.1

# Are the ports open?
nc -zv 10.0.1.1 6379   # Redis
nc -zv 10.0.1.1 5432   # PostgreSQL

# Check private network interface status
ip addr show enp7s0
```

### 3. Check System Logs (dmesg)

```bash
# Recent kernel/system messages
dmesg | tail -100

# Look for specific events
dmesg | grep -E "systemd|redis|postgresql|enp7s0"
```

**What to look for in dmesg:**

```
# systemd reload (causes service restarts)
systemd[1]: systemd 255.4-1ubuntu8.12 running in system mode

# Private network interface issues
hc-net-ifup@enp7s0.service: Failed with result 'exit-code'

# Service stops
redis-server.service: Deactivated successfully
Stopped redis-server.service

# Journal restarts (indicates system-wide reload)
systemd-journald[...]: Received SIGTERM from PID 1 (systemd)
```

### 4. Check for Automatic Updates

Ubuntu runs `unattended-upgrades` daily (typically around 6 AM) to install security updates.

```bash
# Recent automatic updates
cat /var/log/apt/history.log | tail -100

# Older updates (compressed)
zcat /var/log/apt/history.log*.gz | tail -100

# Unattended-upgrades specific log
cat /var/log/unattended-upgrades/unattended-upgrades.log | tail -50
```

**Example entry that caused an outage:**

```
Start-Date: 2026-01-31  06:32:07
Commandline: /usr/bin/unattended-upgrade
Upgrade: libssl-dev:arm64 (3.0.13-0ubuntu3.6, 3.0.13-0ubuntu3.7),
         libssl3t64:arm64 (3.0.13-0ubuntu3.6, 3.0.13-0ubuntu3.7),
         openssl:arm64 (3.0.13-0ubuntu3.6, 3.0.13-0ubuntu3.7)
End-Date: 2026-01-31  06:32:09
```

**High-impact packages that can cause connection drops:**

| Package | Impact |
|---------|--------|
| `openssl`, `libssl*` | Terminates all SSL connections |
| `systemd*` | May restart services, reload daemons |
| `postgresql*` | Database restart |
| `redis*` | Redis restart |
| `linux-image*` | Requires reboot (won't auto-reboot by default) |

### 5. Check Hatchbox Deploys

```bash
# Recent deploys (most recent last)
ls -la /home/deploy/pagecord/releases/ | tail -10
```

Timestamps are in format `YYYYMMDDHHMMSS`. Compare with error timestamps to rule out deploy-related issues.

### 6. Check Resource Usage

```bash
# Memory
free -h

# Disk space (full disk can crash services)
df -h

# File descriptors
cat /proc/sys/fs/file-nr

# Check for OOM killer activity
dmesg | grep -i "out of memory\|oom"
```

### 7. Check journalctl for Specific Timeframes

```bash
# Events around a specific time (adjust timezone as needed)
journalctl --since "2026-01-31 06:30" --until "2026-01-31 06:35"

# Follow logs in real-time
journalctl -f

# Logs for a specific service
journalctl -u redis-server --since "1 hour ago"
journalctl -u postgresql --since "1 hour ago"
```

## Understanding unattended-upgrades

### What It Is

A service that automatically installs security updates. Enabled by default on Ubuntu servers.

### When It Runs

```bash
# Check the timer schedule
systemctl list-timers | grep apt
```

### What It Upgrades

By default, only security updates from Ubuntu's security repository - not all available updates.

### Configuration

```bash
# View current configuration
cat /etc/apt/apt.conf.d/50unattended-upgrades | grep -v "^//" | grep -v "^$"

# Check auto-reboot settings
grep -i reboot /etc/apt/apt.conf.d/50unattended-upgrades
```

### Optional: Email Notifications

To receive emails when updates occur, you need a mail transfer agent (MTA) configured:

```bash
# Check what's installed
dpkg -l | grep -E "postfix|exim|sendmail|msmtp"
```

Lightweight option using msmtp with Resend:

```bash
sudo apt install msmtp msmtp-mta

# Configure /etc/msmtprc with your SMTP credentials
# Then add to /etc/apt/apt.conf.d/50unattended-upgrades:
# Unattended-Upgrade::Mail "sysadmin@pagecord.com";
```

## Sentry Integration

When investigating Sentry errors, look for:

1. **Timestamp correlation** - Match error time with system events
2. **Caused by chain** - The root cause is often nested:
   ```
   ActiveRecord::DatabaseConnectionError
     caused by: PG::ConnectionBad: Connection refused
       caused by: PG::ConnectionBad: terminating connection due to administrator command
   ```
3. **Multiple errors at same time** - Indicates infrastructure event, not application bug

## Common Scenarios

### Scenario: SSL Connection Closed Unexpectedly

**Symptoms:**
- `PG::ConnectionBad: SSL connection has been closed unexpectedly`
- `FATAL: terminating connection due to administrator command`

**Cause:** OpenSSL was upgraded by unattended-upgrades

**Verification:**
```bash
grep -i ssl /var/log/apt/history.log | tail -5
```

**Resolution:** Self-healing. Connections automatically reconnect.

### Scenario: Both Redis and PostgreSQL Fail Simultaneously

**Symptoms:**
- `RedisClient::CannotConnectError` and `ActiveRecord::DatabaseConnectionError`
- Both pointing to `10.0.1.1`
- Same timestamp

**Cause:** Private network interface disruption or systemd reload

**Verification:**
```bash
dmesg | grep -E "enp7s0|hc-net-ifup"
journalctl --since "TIME" --until "TIME+5min" | grep -E "network|reload"
```

### Scenario: Services Restarted

**Symptoms:** Connection errors followed by recovery

**Cause:** systemd daemon-reload (often triggered by package updates)

**Verification:**
```bash
dmesg | grep "systemd\[1\]:"
```

Look for lines like:
```
systemd[1]: systemd 255.4-1ubuntu8.12 running in system mode
```

## Preventive Measures

1. **Monitor unattended-upgrades log** after seeing connection errors
2. **Check Sentry for error clustering** - multiple errors at same timestamp = infrastructure
3. **Consider scheduling updates** during low-traffic periods (edit `/etc/apt/apt.conf.d/50unattended-upgrades`)
4. **Don't disable security updates** - brief outages are acceptable for security

## Quick Diagnostic Checklist

When you see production connection errors:

- [ ] Are both Redis and PostgreSQL affected? (Infrastructure issue)
- [ ] What time did it occur? (Check against apt history)
- [ ] Was there a recent deploy? (Check releases directory)
- [ ] What does dmesg show around that time?
- [ ] Is the issue ongoing or resolved? (Check service status)
- [ ] Any resource exhaustion? (Memory, disk, file descriptors)
