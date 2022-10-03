class App
  hash_branch("entries") do |r|
    @account_batches = Batch.of_account(@account_ds[:id])
    @current_batch = Batch[Account[@account_ds[:id]].active_batch_id]

    unless @current_batch
      flash["error"] = "No Active batch found, please create or one or make one active"
      r.redirect "/batches"
    end

    r.is do
      r.get do
        # Request entries of a specific batch with its id as query param
        if (batch_id = tp.pos_int("batch_id"))

          unless account_owns_batch?(Account[@account_ds[:id]], batch_id)
            response.status = 404
            r.halt
          end

          batch = Batch[batch_id]

          @batch_info = {id: batch.id, name: batch.name, target: batch.target || "/"}
          @entries = Entry.all_with_deltas(account_id: @account_ds[:id], batch_id: batch_id,
            batch_target: batch.target.to_f)

        # Request all entries of all batches
        elsif tp.str("all_batches") == "true"
          @batch_info = {name: "All Batches"}
          @entries = Entry.all_with_deltas(account_id: @account_ds[:id], batch_id: "all",
            batch_target: nil)
          @all_batches = true

        # Request entries of the current batch - default action
        else
          @batch_info = {name: @current_batch.name, target: @current_batch.target || "/"}
          @entries = Entry.all_with_deltas(account_id: @account_ds[:id], batch_id: @current_batch.id,
            batch_target: @current_batch.target.to_f)
        end

        Entry.add_bmi!(@entries, Mensuration.where(account_id: @account_ds[:id]).first.height)
        @chart_data = @entries.map { {day: _1.day, weight: _1.weight, delta: _1.delta} }.reverse

        unless @entries.size < 2
          @stats = Stats.new(@entries, @current_batch.target.to_f)
        end

        view "entries_index"
      end

      r.post do
        @entry = Entry.new
        submitted = {day: tp.date("day"),
                      weight: h(tp.str("weight")),
                      note: h(tp.str("note")),
                      batch_id: tp.pos_int("batch-id"),
                      account_id: @account_ds[:id]}

        @entry.set(submitted)

        # valid_weight_string cannot be validated at the model level due to encryption
        # account_owns_batch could be, but copmlicates the model tests
        if @entry.valid? && valid_weight_string?(submitted[:weight]) &&
            account_owns_batch?(Account[@account_ds[:id]], submitted[:batch_id])

          @entry.save
          flash["notice"] = "New entry saved"
          r.redirect
        end

        flash.now["error"] = if !account_owns_batch?(Account[@account_ds[:id]], submitted[:batch_id])
          "Invalid batch id provided"
        elsif !valid_weight_string?(submitted[:weight])
          "Invalid weight, must be between 20.0 and 999.9"
        else
          format_flash_error(@entry)
        end

        @batch_info = {name: @current_batch.name, target: @current_batch.target || "/"}

        view "entries_new"
      end
    end

    r.is "new" do
      @entry = Entry.new
      @most_recent_weight = Entry.most_recent_weight(@account_ds[:id])
      @batch_info = {name: @current_batch.name, target: @current_batch.target || "/"}
      view "entries_new"
    end

    r.on Integer do |id|
      @entry = Entry[id]

      unless @entry
        response.status = 404
        r.halt
      end

      unless @entry.account_id == @account_ds[:id]
        response.status = 403
        r.halt
      end

      @batch_info = {name: @entry.batch.name, target: @entry.batch.target || "/", id: @entry.batch.id}

      r.is do
        r.post do
          submitted = {day: tp.date("day"),
                        weight: h(tp.str("weight")),
                        note: h(tp.str("note")),
                        batch_id: tp.pos_int("batch-id"),
                        account_id: @account_ds[:id]}

          @entry.set(submitted)

          if @entry.valid? && valid_weight_string?(submitted[:weight]) &&
              account_owns_batch?(Account[@account_ds[:id]], submitted[:batch_id])

            @entry.save
            flash["notice"] = "Entry has been updated"
            r.redirect "/entries"
          end

          flash.now["error"] = if !account_owns_batch?(Account[@account_ds[:id]], submitted[:batch_id])
            "Invalid batch id provided"
          elsif !valid_weight_string?(submitted[:weight])
            "Invalid weight, must be between 20.0 and 999.9"
          else
            format_flash_error(@entry)
          end

          view "entries_edit"
        end
      end

      r.get "edit" do
        view "entries_edit"
      end

      r.post "delete" do
        if @entry.delete
          flash["notice"] = "Entry has been deleted"
        else
          flash["error"] = "Something went wrong, entry has NOT been deleted"
        end
        r.redirect "/entries"
      end
    end
  end
end
