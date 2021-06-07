"use strict"

const confirmBatchDeletionCheckBox = document.querySelector("#confirm-delete-batch-checkbox");
confirmBatchDeletionCheckBox.addEventListener("click", toggleDeleteBatchButton);

const confirmDeleteBatchButton = document.querySelector("#confirm-delete-batch-button");
confirmDeleteBatchButton.addEventListener("click", batchDeletionLastConfirmation);

function toggleDeleteBatchButton(e) {
  confirmDeleteBatchButton.classList.toggle("disabled");
}

function batchDeletionLastConfirmation(e) {
  if (!confirm("You are about to permanently delete a batch and all its related entries. This is your last chance to cancel")) {
    e.preventDefault();
    return;
  }
}
