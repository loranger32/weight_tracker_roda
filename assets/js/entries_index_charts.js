"use strict"

let myChart;
let selectedDayOfWeek = 7;

const entriesChartRawData = document.querySelector("#chart-entries").innerHTML;
const allRawDays = JSON.parse(entriesChartRawData);

const barDisplayButton = document.querySelector("#bar_display_button");
const lineDisplayButton = document.querySelector("#line_display_button");
barDisplayButton.addEventListener('click', displayBarChart);
lineDisplayButton.addEventListener('click', displayLineChart);

const selectDayOfWeek = document.querySelector("#select_day_of_week");
selectDayOfWeek.addEventListener("change", DisplayChartByDayOfWeek);

const redBackGround = 'rgba(200, 0, 0, 0.2)';
const greenBackGround = 'rgba(0, 200, 0, 0.2)';
const blueBackGround = 'rgba(0, 0, 200, 0.2)';
const redBorder = 'rgba(255, 0, 0, 1)';
const greenBorder = 'rgba(0, 255, 0, 1)';
const blueBorder = 'rgba(0, 0, 255, 1)';
const lineChart = 'line';
const barChart = 'bar';
let currentChartType = lineChart;
const allDays = formatDays(allRawDays);

function formatDays(rawDays) {
  return {
    days: rawDays.map(x => x.day),
    weights: rawDays.map(x => x.weight),
    backgroundColors: rawDays.map(x => chooseBackgroundColorFromDelta(x.delta)),
    borderColors: rawDays.map(x => chooseBorderColorFromDelta(x.delta)),
  }
}

function chooseBackgroundColorFromDelta(delta) {
  if (delta > 0) {
    return redBackGround;
  } else if (delta < 0) {
    return greenBackGround;
  } else {
    return blueBackGround;
  }
}

function chooseBorderColorFromDelta(delta) {
  if (delta > 0) {
    return redBorder;
  } else if (delta < 0) {
    return greenBorder;
  } else {
    return blueBorder;
  }   
}

function generateChart(chartType, days) {
  var ctx = document.getElementById('myChart').getContext('2d');
  var myChart = new Chart(ctx, {
    type: chartType,
    data: {
      labels: days.days,
      datasets: [{
        label: 'weight',
        data: days.weights,
        backgroundColor: days.backgroundColors,
        borderColor: days.borderColors,
        borderWidth: 1
      }]
    },
    options: {
      scales: {
        y: {
          beginAtZero: false
        }
      }
    }
  });
  return myChart;
}

function selectDaysToDisplay() {
  if (selectedDayOfWeek == 7) {
    return allDays;
  } else {
    const selectedDays = allRawDays.filter(x => new Date(x.day).getDay() == selectedDayOfWeek);
    return formatDays(selectedDays);
  }
}

function displayChart(type) {
  if (myChart) {
    myChart.destroy();
  }
  const days = selectDaysToDisplay();
  myChart = generateChart(type, days);
}

function displayLineChart() {
  currentChartType = lineChart;
  displayChart('line');
}

function displayBarChart() {
  currentChartType = barChart;
  displayChart('bar');
}

function DisplayChartByDayOfWeek(e) {
  const selectedValue = e.target.value;
  console.log("triggered");

  if (["0", "1", "2", "3", "4", "5", "6", "7"].includes(selectedValue)) {
    selectedDayOfWeek = parseInt(selectedValue, 10);
    if (currentChartType == lineChart) {
      displayLineChart();
    }
    else if (currentChartType == barChart) {
      displayBarChart()
    }
    else {
      console.log(`Invalid day of week value. Got: ${selectedValue}`);
    }
  }
}

displayLineChart();
