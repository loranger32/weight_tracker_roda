class App
  hash_branch("mensurations") do |r|
    @mensuration = Account[@account_ds[:id]].mensuration

    r.get do
      view "mensuration_edit"
    end

    r.post do
      height = tp.pos_int("height")

      unless valid_height?(height)
        flash["error"] = "Incorrect height value, must be integer between 50 and 250"
        r.redirect
      end

      @mensuration.set(height: height.to_s)

      if @mensuration.valid?
        @mensuration.save
        flash["notice"] = "Mensuration successfully submitted"
        r.redirect "/account"
      else
        flash["error"] = format_flash_error(@mensuration)
        r.redirect
      end
    end
  end
end

