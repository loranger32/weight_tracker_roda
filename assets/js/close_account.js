"use strict"

const closeAccountButton = document.querySelector("#close_account_button");
const confirmDeleteDataCheckbox = document.querySelector("#confirm-delete-data");
const closeAccountForm = document.querySelector("#close-account-form");

confirmDeleteDataCheckbox.addEventListener('click', toggleCloseAccountButton);
closeAccountForm.addEventListener('submit', confirmAccountDeletion);

function toggleCloseAccountButton(e) {
	if (confirmDeleteDataCheckbox.checked == true) {
		closeAccountButton.classList.remove('disabled');
	} else {
		closeAccountButton.classList.add('disabled');
	}
}

function confirmAccountDeletion(e) {
  if (!confirm("Are you sure you want to permanently close your account ? This is the last chance to cancel")) {
    e.preventDefault();
    return;
  } 
}

