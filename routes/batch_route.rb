module WeightTracker
  class App
    hash_branch("batches") do |r|
      # TODO - Ugly - to refactor
      @current_batch = Batch[Account[@account_ds[:id]].active_batch_id]
      
      r.is do
        r.get do
          @batches = Account[@account_ds[:id]].batches
          view "batch_index"
        end
      end

      r.on Integer do |batch_id|
        @batch = Batch[batch_id]
        
        unless @batch
          response.status = 404
          r.halt
        end

        unless @batch.account_id == @account_ds[:id]
          response.status = 403
          r.halt
        end

        r.is "edit" do
          view "batch_edit"
        end
      end
    end
  end
end
