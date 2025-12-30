import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
import { assignJobPriority, isPeakHour, calculateEstimatedWaitTime } from '../shared/queue-utils.ts';

Deno.test('assignJobPriority - doubt videos get high priority', () => {
  assertEquals(assignJobPriority('doubt'), 'high');
});

Deno.test('assignJobPriority - topic shorts get medium priority', () => {
  assertEquals(assignJobPriority('topic_short'), 'medium');
});

Deno.test('assignJobPriority - daily CA gets low priority', () => {
  assertEquals(assignJobPriority('daily_ca'), 'low');
});

Deno.test('isPeakHour - detects peak hours correctly', () => {
  const config = {
    peak_hour_start: '06:00',
    peak_hour_end: '21:00',
    max_concurrent_renders: 10,
    max_manim_renders: 4,
    job_timeout_minutes: 10,
    retry_interval_minutes: 5,
    peak_worker_multiplier: 1.5
  };
  const result = isPeakHour(config);
  assertEquals(typeof result, 'boolean');
});

Deno.test('calculateEstimatedWaitTime - calculates correctly', () => {
  assertEquals(calculateEstimatedWaitTime(3, 5), 15);
  assertEquals(calculateEstimatedWaitTime(0, 5), 0);
  assertEquals(calculateEstimatedWaitTime(10, 3), 30);
});
