class TruncateAuditLogsJob
  include SuckerPunch::Job

  def perform(account_id)
    delete_old_logs!(account_id) if has_more_than_100_logs?(account_id)
  end

  private

  def has_more_than_100_logs?(account_id)
    DB[:account_authentication_audit_logs].where(account_id: account_id).count > 100
  end

  def delete_old_logs!(account_id)
    DB[:account_authentication_audit_logs]
      .where(account_id: account_id)
      .order(:at)
      .reverse
      .offset(99)
      .select_map(:id)
      .each { DB[:account_authentication_audit_logs].where(id: _1).delete }
    # DB[:account_authentication_audit_logs].where(id: account_id){at > Time.at(Time.now - (30*60*60*24))}.order(:at).all
  end
end
