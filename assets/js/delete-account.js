"use strict"

const userName = document.querySelector("#user_name").textContent;

const deleteAccountButton = document.querySelector("#delete-acount-button");
deleteAccountButton.addEventListener("click", confirmAccountDeletion);

function confirmAccountDeletion(e) {
  const confirmationText = prompt("This will permanently delete this account and all related data ? Type in the username to confirm");
  
  if (confirmationText != userName) {
    e.preventDefault();
    alert("User name do not match, account deletion has been canceled");
    return;
  }
}
