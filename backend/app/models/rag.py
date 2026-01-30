import uuid
from sqlalchemy import Column, String, Text, JSON, DateTime
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.sql import func
from app.db.base import Base

# Note: pgvector would be imported here in a real env, but strictly for SQLAlquemy definitions without the extension installed locally, we might stub it or just comment it out.
# For this file, I will define it as generic ARRAY(Float) for schema representation, but in prod it requires `from pgvector.sqlalchemy import Vector`

class RAGDocument(Base):
    __tablename__ = "rag_documents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    content_chunk = Column(Text, nullable=False)
    
    # Embedding: In production use Vector(768) from pgvector
    # embedding = Column(Vector(768)) 
    
    metadata_json = Column(JSON, default={}) # source, page, section
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
