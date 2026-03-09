# Backend Walkthrough - AI Assistant Enhancements

This document summarizes the improvements made to the AI service and chat controller to support conversational maintenance requests and better context handling.

## Key Changes

### [AIService.ts](src/services/ai.service.ts)
- **Model Upgrade**: Switched to `gemini-3.1-flash-lite-preview` for better reasoning and parsing.
- **Contextual Prompting**: 
    - Fixed string interpolation for `residentInfo` and `availableObjects`.
    - Added **Rule 6**: Explicitly instructs the AI to ask for specific damage details (e.g., "how is it broken?") if the user input is vague, before generating the JSON request.
- **Robust JSON Parsing**: Added an extraction layer that uses regex to find JSON blocks within conversational text, preventing crashes when the AI replies with both a message and data.
- **Urgency Logic**: Standardized "normal" vs "emergency" rules (e.g., pipe bursts are emergencies).

### [chat.controller.ts](src/controllers/chat.controller.ts)
- **History Formatting**: Fixed an issue where chat history was being passed to the AI with escaped template literal syntax, ensuring the AI can correctly "remember" previous turns.
- **Metadata Reporting**: Added `raw_prompt` and `raw_response` logging (optional/conditional) to help debug AI intent mismatches.

## Known Limitations / TODO
- `request_preview` parsing in the frontend is still being stabilized (handled in Phase 9).
- Evaluation/Feedback system for AI responses is not yet fully linked to the repair database.
