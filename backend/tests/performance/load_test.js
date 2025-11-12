// backend/tests/performance/load_test.js
const autocannon = require('autocannon');

// اختبار تحمل API
async function runLoadTest() {
  const result = await autocannon({
    url: 'http://localhost:3000/api/classes',
    connections: 100, // 100 اتصال متزامن
    duration: 30, // 30 ثانية
    headers: {
      'Authorization': 'Bearer test-token',
    },
  });
  
  console.log('Load Test Results:');
  console.log(`Requests: ${result.requests.total}`);
  console.log(`Throughput: ${result.throughput.average} req/sec`);
  console.log(`Latency: ${result.latency.mean}ms average`);
  console.log(`Errors: ${result.errors}`);
}

runLoadTest();
