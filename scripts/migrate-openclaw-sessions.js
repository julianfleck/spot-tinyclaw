#!/usr/bin/env node
/**
 * OpenClaw to Claude Code Session Transcript Migration
 *
 * Converts OpenClaw session JSONL files to Claude Code format
 * for provenance and continuity of Spot's conversation history.
 *
 * Usage:
 *   node migrate-openclaw-sessions.js <input-dir> <output-dir>
 *
 * Example:
 *   node migrate-openclaw-sessions.js ./openclaw-sessions ./claude-sessions
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Generate a UUID v4
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// Map of OpenClaw IDs to generated UUIDs
const idMap = new Map();

function getOrCreateUUID(openclawId) {
  if (!openclawId) return null;
  if (!idMap.has(openclawId)) {
    idMap.set(openclawId, generateUUID());
  }
  return idMap.get(openclawId);
}

// Convert OpenClaw tool call to Claude Code tool_use format
function convertToolCall(toolCall) {
  return {
    type: 'tool_use',
    id: toolCall.id,
    name: toolCall.name,
    input: toolCall.arguments || {},
    caller: { type: 'direct' }
  };
}

// Convert OpenClaw content array to Claude Code format
function convertContent(content) {
  if (!Array.isArray(content)) return content;

  return content.map(item => {
    if (item.type === 'toolCall') {
      return convertToolCall(item);
    }
    if (item.type === 'thinking') {
      return {
        type: 'thinking',
        thinking: item.thinking,
        signature: item.thinkingSignature || item.signature
      };
    }
    return item;
  });
}

// Convert OpenClaw tool result to Claude Code format
function convertToolResult(entry) {
  const content = entry.content || [];
  let resultContent = '';
  let isError = false;

  if (Array.isArray(content)) {
    resultContent = content.map(c => c.text || '').join('\n');
  } else if (typeof content === 'string') {
    resultContent = content;
  }

  if (entry.isError) {
    isError = true;
  }

  return {
    tool_use_id: entry.toolCallId,
    type: 'tool_result',
    content: resultContent,
    is_error: isError
  };
}

// Convert a single OpenClaw entry to Claude Code format
function convertEntry(entry, sessionId, cwd) {
  const baseFields = {
    sessionId,
    version: '2.1.62',
    gitBranch: 'HEAD',
    isSidechain: false,
    userType: 'external',
    cwd: cwd || '/home/tinyclaw/tinyclaw-workspace/spot'
  };

  switch (entry.type) {
    case 'session':
      // Session entry becomes a marker but doesn't directly translate
      // We'll use this to extract session metadata
      return null;

    case 'model_change':
    case 'thinking_level_change':
    case 'custom':
      // These OpenClaw-specific entries don't have direct Claude Code equivalents
      // Skip them but could log for debugging
      return null;

    case 'message':
      const msg = entry.message;
      if (!msg) return null;

      const uuid = getOrCreateUUID(entry.id);
      const parentUuid = getOrCreateUUID(entry.parentId);

      if (msg.role === 'user') {
        return {
          ...baseFields,
          parentUuid,
          type: 'user',
          message: {
            role: 'user',
            content: msg.content
          },
          uuid,
          timestamp: entry.timestamp || new Date().toISOString(),
          permissionMode: 'bypassPermissions'
        };
      } else if (msg.role === 'assistant') {
        return {
          ...baseFields,
          parentUuid,
          message: {
            model: msg.model || entry.model || 'claude-opus-4-5',
            id: `msg_${uuid.substring(0, 24)}`,
            type: 'message',
            role: 'assistant',
            content: convertContent(msg.content),
            stop_reason: msg.stopReason === 'toolUse' ? 'tool_use' :
                        msg.stopReason === 'endTurn' ? 'end_turn' :
                        msg.stopReason || 'end_turn',
            stop_sequence: null,
            usage: msg.usage || entry.usage || {
              input_tokens: 0,
              output_tokens: 0
            }
          },
          requestId: `req_${uuid.substring(0, 24)}`,
          type: 'assistant',
          uuid,
          timestamp: entry.timestamp || new Date().toISOString()
        };
      }
      return null;

    case 'toolResult':
      // Tool results in Claude Code are embedded in user messages
      const toolResultUuid = getOrCreateUUID(entry.id);
      const toolResultParentUuid = getOrCreateUUID(entry.parentId);

      return {
        ...baseFields,
        parentUuid: toolResultParentUuid,
        type: 'user',
        message: {
          role: 'user',
          content: [convertToolResult(entry)]
        },
        uuid: toolResultUuid,
        timestamp: entry.timestamp || new Date().toISOString(),
        toolUseResult: entry.details || entry.content,
        sourceToolAssistantUUID: toolResultParentUuid
      };

    default:
      console.warn(`Unknown entry type: ${entry.type}`);
      return null;
  }
}

async function convertFile(inputPath, outputPath) {
  const sessionId = path.basename(inputPath, '.jsonl').replace('.deleted', '');

  // Clear the ID map for each file
  idMap.clear();

  const fileStream = fs.createReadStream(inputPath);
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });

  const outputLines = [];
  let cwd = '/home/tinyclaw/tinyclaw-workspace/spot';
  let firstTimestamp = null;

  // First pass: collect session info
  for await (const line of rl) {
    if (!line.trim()) continue;
    try {
      const entry = JSON.parse(line);
      if (entry.type === 'session') {
        cwd = entry.cwd || cwd;
        firstTimestamp = entry.timestamp;
      }
    } catch (e) {
      // Skip invalid JSON lines
    }
  }

  // Reset for second pass
  fileStream.destroy();
  const fileStream2 = fs.createReadStream(inputPath);
  const rl2 = readline.createInterface({
    input: fileStream2,
    crlfDelay: Infinity
  });

  // Add initial queue operations
  if (firstTimestamp) {
    outputLines.push(JSON.stringify({
      type: 'queue-operation',
      operation: 'enqueue',
      timestamp: firstTimestamp,
      sessionId,
      content: '[migrated from OpenClaw]'
    }));
    outputLines.push(JSON.stringify({
      type: 'queue-operation',
      operation: 'dequeue',
      timestamp: firstTimestamp,
      sessionId
    }));
  }

  for await (const line of rl2) {
    if (!line.trim()) continue;
    try {
      const entry = JSON.parse(line);
      const converted = convertEntry(entry, sessionId, cwd);
      if (converted) {
        outputLines.push(JSON.stringify(converted));
      }
    } catch (e) {
      console.error(`Error parsing line in ${inputPath}: ${e.message}`);
    }
  }

  if (outputLines.length > 2) { // More than just queue operations
    fs.writeFileSync(outputPath, outputLines.join('\n') + '\n');
    return true;
  }
  return false;
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    console.log('Usage: node migrate-openclaw-sessions.js <input-dir> <output-dir>');
    console.log('');
    console.log('Converts OpenClaw session JSONL files to Claude Code format.');
    process.exit(1);
  }

  const inputDir = args[0];
  const outputDir = args[1];

  if (!fs.existsSync(inputDir)) {
    console.error(`Input directory does not exist: ${inputDir}`);
    process.exit(1);
  }

  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const files = fs.readdirSync(inputDir).filter(f => f.endsWith('.jsonl'));
  console.log(`Found ${files.length} JSONL files to convert`);

  let converted = 0;
  let skipped = 0;

  for (const file of files) {
    const inputPath = path.join(inputDir, file);
    // Remove .deleted suffix if present for output
    const outputFile = file.replace(/\.deleted\.\d{4}-\d{2}-\d{2}T[\d-]+\.\d+Z$/, '');
    const outputPath = path.join(outputDir, outputFile);

    try {
      const success = await convertFile(inputPath, outputPath);
      if (success) {
        converted++;
        console.log(`✓ ${file}`);
      } else {
        skipped++;
        console.log(`○ ${file} (no content)`);
      }
    } catch (e) {
      console.error(`✗ ${file}: ${e.message}`);
      skipped++;
    }
  }

  console.log('');
  console.log(`Converted: ${converted}, Skipped: ${skipped}`);
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
