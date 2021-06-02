"use strict"

const userName = document.querySelector("#user_name").textContent;
const actionInfo = document.querySelector("#action-info").textContent;
const adminActionButton = document.querySelector("#admin-action-button");
adminActionButton.addEventListener("click", confirmAdminAction);

function confirmAdminAction(e) {
  const confirmationText = prompt(`${actionInfo} Type in the username to confirm.`);

  if (confirmationText != userName) {
    e.preventDefault();
    alert("User name do not match, action has been canceled");
    return;
  }
}
