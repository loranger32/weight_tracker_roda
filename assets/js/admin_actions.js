"use strict"

const userName = document.querySelector("#user_name").textContent;
const verifyAccountBtn = document.querySelector("#verify-account-button");
const closeAccountBtn = document.querySelector("#close-account-button");
const openAccountBtn = document.querySelector("#open-account-button");
const deleteAccountBtn = document.querySelector("#delete-account-button");

[verifyAccountBtn, closeAccountBtn, openAccountBtn, deleteAccountBtn].forEach(function (el) {
  if (el) {
    el.addEventListener("click", confirmAction);  
  }
});

const confirmActionPromptText = {
  "close-account-button": "You are about to close this account.",
  "verify-account-button": "You are about to verify this account.",
  "open-account-button": "You are about to reopen this account.",
}
                                                            
const confirmDeleteAccountButton = document.querySelector("#confirm-delete-account-button");
confirmDeleteAccountButton.addEventListener("click", confirmAccountDeletion);

const confirmDeleteAccountCheckbox = document.querySelector("#confirm-delete-account-checkbox");
confirmDeleteAccountCheckbox.addEventListener("click", toggleConfirmDeleteAccountButton);

function confirmAction(e) {
  const confirmationText = prompt(`${confirmActionPromptText[e.target.id]} Type in the username to confirm.`);

  if (confirmationText != userName) {
    e.preventDefault();
    alert("User name do not match, action has been canceled");
    return;
  }
}

function toggleConfirmDeleteAccountButton(e) {
  confirmDeleteAccountButton.classList.toggle("disabled");
}

function confirmAccountDeletion(e) {
  const confirmationText = prompt("You are about to PERMANENTLY delete this account and ALL its associated data. Do you really want to pursue ? Type in the username to confirm.");

  if (confirmationText != userName) {
    e.preventDefault();
    alert("User name do not match, action has been canceled");
    return;
  }
}
