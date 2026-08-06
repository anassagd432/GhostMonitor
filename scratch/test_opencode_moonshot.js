const { createOpenAI } = require('@ai-sdk/openai');
const { generateText } = require('ai');

const openai = createOpenAI({
  baseURL: 'https://api.moonshot.ai/v1',
  apiKey: 'sk-nzIawOjCd1lFwky6Ryz5nm4t9K2hoJUv42uBOseK3MHt2pZV',
});

async function test() {
  try {
    const { text } = await generateText({
      model: openai('kimi-k2.6'),
      prompt: 'hi',
    });
    console.log('SUCCESS:', text);
  } catch (err) {
    console.error('ERROR:', err);
  }
}

test();
