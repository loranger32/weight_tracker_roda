"use strict"

// Initializes Popovers - Bootstrap 5
var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
  return new bootstrap.Popover(popoverTriggerEl)
})

// TO FIX - Recommanded by Bootstrap 5 docs, ans it works, but generates an error
var popover = new bootstrap.Popover(document.querySelector('.popover-dismiss'), {
    trigger: 'focus'
})


// Page specific JS
const printButton = document.querySelector("#print")
const copyButton = document.querySelector("#copy")


printButton.addEventListener("click", printCodes)
copyButton.addEventListener("click", copy)

function printCodes() {
  window.print();
}

function copy() {
  // Code snippet comes from https://htmldom.dev/copy-text-to-the-clipboard

  let recoveryCodes = document.querySelector("#recovery-codes")
  console.log(recoveryCodes);
  let text = recoveryCodes.textContent;

  // Create a "fake" textarea
  const textAreaEle = document.createElement('textarea');

  // Reset styles
  textAreaEle.style.border = '0';
  textAreaEle.style.padding = '0';
  textAreaEle.style.margin = '0';

  // Set the absolute position
  // User won't see the element
  textAreaEle.style.position = 'absolute';
  textAreaEle.style.left = '-9999px';
  textAreaEle.style.top = `0px`;

  textAreaEle.value = text;

  document.body.appendChild(textAreaEle);

  textAreaEle.focus();
  textAreaEle.select();

  try {
      document.execCommand('copy');
  } catch (err) {
      console.log("Unable to copy recovery codes to clipboard");
  } finally {
      // Remove the textarea
      document.body.removeChild(textAreaEle);
  }
}