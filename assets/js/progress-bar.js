"use strict"

const rawEntryData = document.querySelector("#chart-entries").innerHTML;
const parsedData = JSON.parse(rawEntryData);

const progressJauge = document.querySelector("#progress-jauge");
const remainingJauge = document.querySelector("#remaining-jauge");

const maxWeight = Math.max(...parsedData.map(x => parseFloat(x.weight)));
const targetWeight = parseFloat(document.querySelector("#target-weight").innerHTML);
const actualWeight = parseFloat(parsedData[parsedData.length - 1].weight)

const startingDelta = maxWeight - targetWeight;
const alreadyLost = maxWeight - actualWeight;
const percentage = Math.abs(Math.trunc((alreadyLost / startingDelta) * 100));

progressJauge.style["width"] = `${percentage}%`;
progressJauge.innerHTML = alreadyLost.toFixed(1);
remainingJauge.style["width"] = `${100 - percentage}%`;
remainingJauge.innerHTML = (actualWeight - targetWeight).toFixed(1);