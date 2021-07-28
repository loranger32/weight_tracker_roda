module WeightTracker
  class App
    hash_branch("entries") do |r|
      # TODO - Ugly - to refactor
      current_batch = Batch[Account[@account_ds[:id]].active_batch_id]

      unless current_batch
        flash["error"] = "No Active batch found, please create or one or make one active"
        r.redirect "/batches"
      end

      r.is do
        r.get do
          # Request entries of a specific batch with its id ad query param
          if (batch_id = tp.pos_int("batch_id"))

            unless account_owns_batch?(Account[@account_ds[:id]], batch_id)
              response.status = 404
              r.halt
            end

            batch = Batch[batch_id]

            @batch_info = {name: batch.name, target: batch.target || "/"}
            @entries = Entry.all_with_deltas(account_id: @account_ds[:id], batch_id: batch_id,
                                             batch_target: batch.target.to_f)

          # Request all entries of all batches
          elsif tp.str("all_batches") == "true"
            @batch_info = {name: "All Batches"}
            @entries = Entry.all_with_deltas(account_id: @account_ds[:id], batch_id: "all",
                                             batch_target: nil)
          
          # Request entries of the current batch - default action
          else
            @batch_info = {name: current_batch.name, target: current_batch.target || "/"}
            @entries = Entry.all_with_deltas(account_id: @account_ds[:id], batch_id: current_batch.id,
                                             batch_target: current_batch.target.to_f)
          end

          Entry.add_bmi(@entries, Mensuration.where(account_id: @account_ds[:id]).first.height)

          view "entries_index"
        end

        r.post do
          @entry = Entry.new
          submitted = {day: tp.date("day"),
                       weight: h(tp.str("weight")),
                       note: h(tp.str("note")),
                       account_id: @account_ds[:id]}

          @entry.set(submitted)
          @entry.set(batch_id: current_batch.id)

          if @entry.valid? && valid_weight_string?(submitted[:weight])
            @entry.save
            flash["notice"] = "New entry saved"
            r.redirect
          end

          @batch_info = {name: current_batch.name, target: current_batch.target || "/"}

          if !valid_weight_string?(submitted[:weight])
            flash.now["error"] = "Invalid weight, must be between 20.0 and 999.9"
            view "entries_new"
          else
            flash.now["error"] = format_flash_error(@entry)
            view "entries_new"
          end
        end
      end

      r.is "new" do
        @entry = Entry.new
        @most_recent_weight = Entry.most_recent_weight(@account_ds[:id])
        @batch_info = {name: current_batch.name, target: current_batch.target || "/"}
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


        @batch_info = {name: @entry.batch.name, target: @entry.batch.target || "/"}

        r.is do
          r.post do
            submitted = {day: tp.date("day"),
                         weight: h(tp.str("weight")),
                         note: h(tp.str("note")),
                         account_id: @account_ds[:id]}

            @entry.set(submitted)

            if @entry.valid? && valid_weight_string?(submitted[:weight])
              @entry.save
              flash["notice"] = "Entry has been updated"
              r.redirect "/entries"
            elsif !valid_weight_string?(submitted[:weight])
              flash.now["error"] = "Invalid weight, must be between 20.0 and 999.9"
              view "entries_edit"
            else
              flash.now["error"] = @entry.errors.values.join("\n")
              view "entries_edit"
            end
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
end
