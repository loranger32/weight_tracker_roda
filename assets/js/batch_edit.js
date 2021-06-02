"use strict"

const deleteBatchButton = document.querySelector("#delete-batch-button");
deleteBatchButton.addEventListener("click", displayDeleteBatchForm);

const deleteBatchForm = document.querySelector("#delete-batch-form");

function displayDeleteBatchForm(e) {
    e.preventDefault();
  deleteBatchForm.classList.toggle("invisible");
}

const confirmDeleteBatchButton = document.querySelector("#confirm-delete-batch-button");
confirmDeleteBatchButton.addEventListener("click", batchDeletionLastConfirmation);

const confirmBatchDeletionCheckBox = document.querySelector("#confirm-delete-batch-checkbox");
confirmBatchDeletionCheckBox.addEventListener("click", toggleDeleteBatchButton);

function toggleDeleteBatchButton(e) {
  confirmDeleteBatchButton.classList.toggle("btn-disabled");
}

function batchDeletionLastConfirmation(e) {
  if (!confirm("You are about to permanently delete a batch and all its related entries. This is your last chance to cancel")) {
    e.preventDefault();
    return;
  }
}
