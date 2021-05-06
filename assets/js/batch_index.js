let newButton = document.querySelector("#new-batch-btn");
newButton.addEventListener("click", displayNewBatchForm);

let createBatchButton = document.querySelector("#create-batch-button");
createBatchButton.addEventListener("click", confirmCreateBatch);

let newBatchForm = document.querySelector("#new-batch-form");
let newBatchText = document.querySelector("#newBatchText");

function displayNewBatchForm(e) {
  e.preventDefault();
  if (newBatchForm.classList.contains("invisible")) {
    newBatchForm.classList.remove("invisible");
    newBatchForm.classList.remove("bg-primary");
    newBatchText.classList.add("bg-danger");    
    newBatchText.textContent = "Cancel";
  } else {
    newBatchForm.classList.add("invisible");
    newBatchText.classList.remove("bg-danger");
    newBatchForm.classList.add("bg-primary");
    newBatchText.textContent = "New";
  }
}

function confirmCreateBatch(e) {
  if (!confirm("The new batch will be the new active one. You can change it on the bacthes setting page")) {
    e.preventDefault();
    return;
  } 
}
