from datetime import datetime
import json
import urllib.request
from jose import jwt
from fastapi import HTTPException, status
from app.core.config import get_settings

settings = get_settings()

class AuthService:
    _jwks_cache = None
    _cache_timestamp = 0
    CACHE_TTL = 3600  # 1 hour

    @classmethod
    def _get_jwks(cls):
        current_time = datetime.now().timestamp()
        if cls._jwks_cache and (current_time - cls._cache_timestamp < cls.CACHE_TTL):
            return cls._jwks_cache

        try:
            with urllib.request.urlopen(settings.GOOGLE_JWKS_URL) as response:
                cls._jwks_cache = json.loads(response.read())
                cls._cache_timestamp = current_time
                return cls._jwks_cache
        except Exception as e:
            print(f"Error fetching JWKS: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Could not fetch auth keys"
            )

    @classmethod
    def verify_id_token(cls, token: str) -> dict:
        try:
            # Get the Key ID (kid) from the token header
            header = jwt.get_unverified_header(token)
            kid = header.get("kid")
            if not kid:
                raise ValueError("Invalid token header")

            # Get public keys
            jwks = cls._get_jwks()
            
            # Find the key matching the kid
            rsa_key = {}
            for key in jwks["keys"]:
                if key["kid"] == kid:
                    rsa_key = {
                        "kty": key["kty"],
                        "kid": key["kid"],
                        "use": key["use"],
                        "n": key["n"],
                        "e": key["e"]
                    }
                    if "alg" in key:
                        rsa_key["alg"] = key["alg"]
                    break
            
            if not rsa_key:
                raise ValueError("Public key not found")

            # Verify the token
            payload = jwt.decode(
                token,
                rsa_key,
                algorithms=["RS256"],
                audience=settings.API_AUDIENCE,
                issuer=["https://securetoken.google.com/" + settings.IDENTITY_PLATFORM_PROJECT_ID]
            )
            
            return payload

        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired"
            )
        except jwt.JWTClaimsError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect claims, please check the audience and issuer"
            )
        except Exception as e:
            print(f"Token validation error: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials"
            )
