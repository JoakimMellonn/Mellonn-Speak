String greetingsString() {
  int time = DateTime.now().hour;
  if (time >= 0 && time < 5) return 'Good night';
  if (time >= 5 && time < 12) return 'Good morning';
  if (time >= 12 && time < 18) return 'Good afternoon';
  if (time >= 18 && time < 24) return 'Good evening';
  return 'Hi';
}
