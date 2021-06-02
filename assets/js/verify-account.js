"use strict"

let userName = document.querySelector("#user_name").textContent;
console.log(userName);

let verifyAccountButton = document.querySelector("#verify-acount-button");
verifyAccountButton.addEventListener("click", confirmAccountVerification);

function confirmAccountVerification(e) {
  let confirmationText = prompt("This will verify this account manually ? Type in the username to confirm");

  if (confirmationText != userName) {
    e.preventDefault();
    alert("User name do not match, account verification has been canceled");
    return;
  }
}
