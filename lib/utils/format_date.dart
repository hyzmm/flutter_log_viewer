String formatIntoHHMMSSmmm(DateTime date) {
  return "${date.hour}:${date.minute}:${date.second}.${date.millisecond}";
}
