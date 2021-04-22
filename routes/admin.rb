module WeightTracker
  class App
    hash_branch("admin") do |r|

      unless is_admin?(@account_ds)
        response.status = 403
        r.halt
      end

      rodauth.require_two_factor_setup
      rodauth.require_authentication
      @page_title = "Admin - "
      r.is "accounts" do
        case r.params["query"]
        when "verified"   then @accounts = Account.verified
        when "unverified" then @accounts = Account.unverified
        when "closed"     then @accounts = Account.closed
        when "otp_on"     then @accounts = Account.otp_on
        when "otp_off"    then @accounts = Account.otp_off
        else
          @accounts = Account.all
        end
        view "admin/accounts", layout: "layout-admin"
      end
    end
  end
end
