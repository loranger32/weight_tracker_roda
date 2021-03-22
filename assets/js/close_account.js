console.log("close account from js dir");

const closeAccountButton = document.querySelector("#close_account_button");
const confirmDeleteData = document.querySelector("#confirm-delete-data");

confirmDeleteData.addEventListener('click', toggleCloseAccountButton);

function toggleCloseAccountButton(e) {
	if (confirmDeleteData.checked == true) {
		closeAccountButton.classList.remove('btn-disabled');
	} else {
		closeAccountButton.classList.add('btn-disabled');
	}
}