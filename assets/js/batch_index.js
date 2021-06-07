"use strict"

const createBatchButton = document.querySelector("#create-batch-button");
createBatchButton.addEventListener("click", confirmCreateBatch);

function confirmCreateBatch(e) {
  if (!confirm("The new batch will be the new active one. You can change it on the bacthes setting page")) {
    e.preventDefault();
    return;
  } 
}
