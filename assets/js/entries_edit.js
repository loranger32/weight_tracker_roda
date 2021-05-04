const deleteEntryButton = document.querySelector("#delete-entry-btn");
deleteEntryButton.addEventListener('click', confirmEntryDeletion);

function confirmEntryDeletion(e) {
  if (!confirm("Are you sure you want to delete this entry ? There is no going back")) {
    e.preventDefault();
    return;
  } 
}
