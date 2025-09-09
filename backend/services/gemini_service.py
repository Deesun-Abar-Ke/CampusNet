import os
import json
import time
import google.generativeai as genai
from typing import List, Dict, Optional, Tuple
from config import Config
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GeminiService:
    """
    Service for interacting with Google Gemini API
    Handles text, image, and multimodal interactions with context injection for RAG
    """
    
    def __init__(self):
        """Initialize Gemini service with API key validation"""
        self.api_key = Config.GEMINI_API_KEY
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY is required but not found in environment variables")
        
        # Configure Gemini
        genai.configure(api_key=self.api_key)
        
        # Initialize models
        self.text_model = genai.GenerativeModel('gemini-1.5-flash')
        self.vision_model = genai.GenerativeModel('gemini-1.5-flash')
        
        # MIST-specific system prompt
        self.system_prompt = """
        You are MIST AI Assistant, an intelligent chatbot for Military Institute of Science and Technology (MIST).
        
        Your role:
        - Provide accurate information about MIST academics, admissions, campus life, and research
        - Help students, faculty, and prospective students with their queries
        - Use the provided context from MIST knowledge base when available
        - Be friendly, helpful, and professional
        - If you don't know something specific about MIST, clearly state that and suggest contacting the relevant department
        
        Guidelines:
        - Always prioritize information from the provided context
        - Be concise but comprehensive in your responses
        - Use a helpful and academic tone
        - When discussing academic programs, provide specific details if available
        - For admission queries, provide current and accurate information
        """
        
        logger.info("Gemini service initialized successfully")
    
    def generate_text_response(
        self, 
        user_message: str, 
        context: Optional[str] = None,
        conversation_history: Optional[List[Dict]] = None
    ) -> Tuple[str, float]:
        """
        Generate text response using Gemini with RAG context
        
        Args:
            user_message: User's input message
            context: RAG context from knowledge base
            conversation_history: Previous conversation for context
            
        Returns:
            Tuple of (response_text, processing_time)
        """
        start_time = time.time()
        
        try:
            # Build the prompt with context
            prompt = self._build_prompt(user_message, context, conversation_history)
            
            # Generate response
            response = self.text_model.generate_content(prompt)
            
            # Calculate processing time
            processing_time = time.time() - start_time
            
            logger.info(f"Generated text response in {processing_time:.2f}s")
            return response.text, processing_time
            
        except Exception as e:
            logger.error(f"Error generating text response: {str(e)}")
            processing_time = time.time() - start_time
            return f"I apologize, but I encountered an error processing your request. Please try again later.", processing_time
    
    def analyze_image_with_text(
        self, 
        image_path: str, 
        user_message: str,
        context: Optional[str] = None
    ) -> Tuple[str, float]:
        """
        Analyze image with text prompt using Gemini Vision
        
        Args:
            image_path: Path to the uploaded image
            user_message: User's question about the image
            context: Additional context if available
            
        Returns:
            Tuple of (response_text, processing_time)
        """
        start_time = time.time()
        
        try:
            # Upload the image
            with open(image_path, 'rb') as image_file:
                image_data = image_file.read()
            
            # Build prompt with MIST context
            prompt = f"""
            {self.system_prompt}
            
            Additional Context: {context if context else "No additional context provided"}
            
            User Question: {user_message}
            
            Please analyze the uploaded image and provide a helpful response based on the user's question.
            If the image contains text, extract and explain it. If it's a diagram or chart, describe its contents.
            Relate your analysis to MIST context when relevant.
            """
            
            # Generate response with image
            response = self.vision_model.generate_content([prompt, image_data])
            
            processing_time = time.time() - start_time
            
            logger.info(f"Analyzed image in {processing_time:.2f}s")
            return response.text, processing_time
            
        except Exception as e:
            logger.error(f"Error analyzing image: {str(e)}")
            processing_time = time.time() - start_time
            return f"I apologize, but I couldn't analyze the image. Please make sure it's a valid image file and try again.", processing_time
    
    def process_audio_transcript(
        self, 
        transcript: str, 
        context: Optional[str] = None
    ) -> Tuple[str, float]:
        """
        Process audio transcript (speech-to-text will be handled separately)
        
        Args:
            transcript: Transcribed text from audio
            context: RAG context if available
            
        Returns:
            Tuple of (response_text, processing_time)
        """
        start_time = time.time()
        
        try:
            # Treat as text input with audio context
            prompt = f"""
            {self.system_prompt}
            
            Context from Knowledge Base: {context if context else "No specific context available"}
            
            The user sent an audio message that was transcribed as: "{transcript}"
            
            Please provide a helpful response to their spoken query about MIST.
            """
            
            response = self.text_model.generate_content(prompt)
            processing_time = time.time() - start_time
            
            logger.info(f"Processed audio transcript in {processing_time:.2f}s")
            return response.text, processing_time
            
        except Exception as e:
            logger.error(f"Error processing audio transcript: {str(e)}")
            processing_time = time.time() - start_time
            return f"I apologize, but I couldn't process your audio message. Please try again.", processing_time
    
    def _build_prompt(
        self, 
        user_message: str, 
        context: Optional[str] = None,
        conversation_history: Optional[List[Dict]] = None
    ) -> str:
        """
        Build the complete prompt with system instructions, context, and conversation history
        
        Args:
            user_message: Current user message
            context: RAG context from knowledge base
            conversation_history: Previous messages in the conversation
            
        Returns:
            Complete prompt string
        """
        prompt_parts = [self.system_prompt]
        
        # Add RAG context if available
        if context:
            prompt_parts.append(f"""
            MIST Knowledge Base Context:
            {context}
            
            Please use this context to provide accurate information about MIST when relevant to the user's question.
            """)
        
        # Add conversation history for context
        if conversation_history:
            prompt_parts.append("Previous conversation:")
            for msg in conversation_history[-5:]:  # Last 5 messages for context
                role = "User" if msg.get('role') == 'user' else "Assistant"
                prompt_parts.append(f"{role}: {msg.get('content', '')}")
        
        # Add current user message
        prompt_parts.append(f"Current User Question: {user_message}")
        
        prompt_parts.append("""
        Please provide a helpful, accurate, and friendly response based on the MIST context provided.
        If the question is not related to MIST or if you don't have specific information, 
        acknowledge this and provide general helpful guidance when appropriate.
        """)
        
        return "\n\n".join(prompt_parts)
    
    def validate_response(self, response: str) -> bool:
        """
        Validate if the response is appropriate and not empty
        
        Args:
            response: Generated response text
            
        Returns:
            Boolean indicating if response is valid
        """
        if not response or len(response.strip()) < 10:
            return False
        
        # Check for inappropriate content or errors
        error_indicators = [
            "I cannot",
            "I'm unable to process",
            "Error occurred",
            "Something went wrong"
        ]
        
        return not any(indicator in response for indicator in error_indicators)
    
    def get_embedding(self, text: str) -> List[float]:
        """
        Get text embedding using Gemini embedding model
        Note: This is a placeholder - you might want to use a different embedding service
        
        Args:
            text: Text to embed
            
        Returns:
            List of float values representing the embedding
        """
        try:
            # For now, we'll use a simple approach
            # In production, you might want to use a dedicated embedding service
            result = genai.embed_content(
                model="models/embedding-001",
                content=text,
                task_type="retrieval_document"
            )
            return result['embedding']
        except Exception as e:
            logger.error(f"Error generating embedding: {str(e)}")
            return []
