const closeAccountButton = document.querySelector("#close_account_button");
const confirmDeleteData = document.querySelector("#confirm-delete-data");
const closeAccountForm = document.querySelector("#close-account-form");

confirmDeleteData.addEventListener('click', toggleCloseAccountButton);
closeAccountForm.addEventListener('submit', confirmAccountDeletion);

function toggleCloseAccountButton(e) {
	if (confirmDeleteData.checked == true) {
		closeAccountButton.classList.remove('btn-disabled');
	} else {
		closeAccountButton.classList.add('btn-disabled');
	}
}

function confirmAccountDeletion(e) {
  if (!confirm("Are you sure you want to permanently close your account ? This is the last chance to cancel")) {
    e.preventDefault();
    return;
  } 
}

