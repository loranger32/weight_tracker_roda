"use strict"

const newBatchButton = document.querySelector("#new-batch-btn");
newBatchButton.addEventListener("click", displayNewBatchForm);

const createBatchButton = document.querySelector("#create-batch-button");
createBatchButton.addEventListener("click", confirmCreateBatch);

const newBatchForm = document.querySelector("#new-batch-form");

function displayNewBatchForm(e) {
  e.preventDefault();
  if (newBatchForm.classList.contains("invisible")) {
    newBatchForm.classList.remove("invisible");
    newBatchButton.classList.remove("bg-primary");
    newBatchButton.classList.add("bg-danger");    
    newBatchButton.textContent = "Cancel";
  } else {
    newBatchForm.classList.add("invisible");
    newBatchButton.classList.remove("bg-danger");
    newBatchButton.classList.add("bg-primary");
    newBatchButton.textContent = "New";
  }
}

function confirmCreateBatch(e) {
  if (!confirm("The new batch will be the new active one. You can change it on the bacthes setting page")) {
    e.preventDefault();
    return;
  } 
}
