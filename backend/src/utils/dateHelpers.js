import { endOfDay, endOfMonth, endOfWeek, parseISO, startOfDay, startOfMonth, startOfWeek } from "date-fns";

export const parseDateOrToday = (value) => (value ? parseISO(value) : new Date());
export const dayRange = (value) => {
  const date = parseDateOrToday(value);
  return { start: startOfDay(date), end: endOfDay(date) };
};
export const weekRange = (value) => {
  const date = parseDateOrToday(value);
  return { start: startOfWeek(date), end: endOfWeek(date) };
};
export const monthRange = (value) => {
  const date = parseDateOrToday(value);
  return { start: startOfMonth(date), end: endOfMonth(date) };
};
export const queryDateRange = (query) => ({
  start: query.from ? startOfDay(parseISO(query.from)) : startOfDay(new Date()),
  end: query.to ? endOfDay(parseISO(query.to)) : endOfDay(new Date())
});
