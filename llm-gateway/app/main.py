from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import google.generativeai as genai
import google.ai.generativelanguage as glm
import httpx
import os
from app.rbac import get_allowed_functions
from app.functions import FUNCTION_DECLARATIONS, execute_function

app = FastAPI(title="University LLM Gateway", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8080")


class ChatRequest(BaseModel):
    message: str
    token: str
    conversation_history: Optional[list] = []


class ChatResponse(BaseModel):
    reply: str
    function_called: Optional[str] = None
    data: Optional[dict] = None


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    # 1단계: JWT에서 사용자 역할 추출 및 허용 함수 목록 필터링 (1차 RBAC)
    allowed_functions = await get_allowed_functions(request.token, BACKEND_URL)
    if not allowed_functions:
        raise HTTPException(status_code=403, detail="권한이 없습니다.")

    filtered_declarations = [
        f for f in FUNCTION_DECLARATIONS if f["name"] in allowed_functions
    ]

    # 2단계: Gemini Function Calling
    SYSTEM_PROMPT = (
        "You are an AI assistant for a university information system. "
        "Understand user requests and call appropriate functions to respond. "
        "If the user requests an action not allowed by their role, "
        "say it is not allowed due to access permissions."
    )
    model = genai.GenerativeModel(
        model_name="gemini-2.5-flash",
        tools=filtered_declarations,
    )

    user_message = (SYSTEM_PROMPT + "\n\nUser: " + request.message
                    if not request.conversation_history else request.message)

    # Convert OpenAI-style history (role/content) to Gemini format (role/parts)
    gemini_history = []
    for msg in request.conversation_history:
        role = "model" if msg.get("role") == "assistant" else msg.get("role", "user")
        content = msg.get("content") or msg.get("parts", "")
        parts = content if isinstance(content, list) else [content]
        gemini_history.append({"role": role, "parts": parts})

    chat_session = model.start_chat(history=gemini_history)
    response = chat_session.send_message(user_message)

    # 3단계: Function Call 처리
    if response.candidates[0].content.parts[0].function_call:
        function_call = response.candidates[0].content.parts[0].function_call
        function_name = function_call.name
        function_args = dict(function_call.args)

        # 백엔드 API 호출 (2차 RBAC는 Spring Security가 처리)
        result = await execute_function(
            function_name, function_args, request.token, BACKEND_URL
        )

        # 결과를 Gemini에 전달하여 자연어 응답 생성
        final_response = chat_session.send_message(
            glm.Content(
                parts=[glm.Part(
                    function_response=glm.FunctionResponse(
                        name=function_name,
                        response={"result": result}
                    )
                )]
            )
        )

        return ChatResponse(
            reply=final_response.text,
            function_called=function_name,
            data=result
        )

    return ChatResponse(reply=response.text)


@app.get("/health")
async def health():
    return {"status": "ok"}
