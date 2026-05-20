import httpx
from typing import List


async def get_allowed_functions(token: str, backend_url: str) -> List[str]:
    """백엔드에서 현재 사용자의 역할에 허용된 함수 목록을 조회 (1차 RBAC)"""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{backend_url}/api/rbac/allowed-functions",
            headers={"Authorization": f"Bearer {token}"},
            timeout=10.0
        )
        if response.status_code == 200:
            return response.json()
        return []
