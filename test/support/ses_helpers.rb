module SesHelpers
  def stub_ses(suppressions: [], status: "HEALTHY", sending_enabled: true, sent: 0, bounces: 0, complaints: 0)
    client = stub(
      list_suppressed_destinations: [ stub(suppressed_destination_summaries: suppressions) ],
      get_account: stub(enforcement_status: status, sending_enabled: sending_enabled),
      batch_get_metric_data: stub(errors: [], results: [
        stub(id: "sent", values: [ sent ]),
        stub(id: "bounces", values: [ bounces ]),
        stub(id: "complaints", values: [ complaints ])
      ])
    )
    Aws::SESV2::Client.stubs(:new).returns(client)
    client
  end

  def ses_suppression(email, reason: "BOUNCE", last_update_time: 1.day.ago)
    stub(email_address: email, reason: reason, last_update_time: last_update_time)
  end
end
