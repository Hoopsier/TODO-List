const readline = require("readline-sync");//NOTE: Works, but not for lsp
const tasks = require("../tasks.json")
function addTask() {
  readline.question()
}
function getTasks() {
  console.log(tasks);
}
getTasks()
