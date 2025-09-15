import os
import json
import requests
import logging
from typing import List, Dict, Any, Optional

# Configure logging
logger = logging.getLogger(__name__)

class GroqService:
    def __init__(self, use_chatbot_key=False):
        if use_chatbot_key:
            self.api_key = os.getenv('GROQ_API_KEY_chatBot')
        else:
            self.api_key = os.getenv('GROQ_API_KEY')
            
        self.base_url = "https://api.groq.com/openai/v1/chat/completions"
        self.model = "llama-3.1-8b-instant"  # Using currently supported model
        
        if not self.api_key:
            raise ValueError("GROQ_API_KEY not found in environment variables")
        
        print(f"INFO:services.groq_service:Groq service initialized successfully ({'Chatbot' if use_chatbot_key else 'General'} API key)")
    
    def _create_system_prompt(self) -> str:
        """Create comprehensive system prompt for MIST chatbot with strict anti-hallucination guidelines"""
        return """You are MIST AI Assistant 🎓, an intelligent chatbot for Military Institute of Science and Technology (MIST) in Bangladesh. You provide beautifully formatted, accurate responses based ONLY on the provided context.

**🚨 CRITICAL ANTI-HALLUCINATION RULES:**
1. ❌ NEVER make up information about MIST if not provided in context
2. ❌ NEVER guess or assume facts about courses, admission, faculty, or facilities
3. ❌ NEVER provide outdated information from your training data
4. ✅ ONLY use information explicitly provided in the context below
5. ✅ If context doesn't contain the answer, say "I don't have current information about this"
6. ✅ Always cite your sources when possible

**Your Response Priority Order:**
1. � **First Priority**: Answer using provided MIST knowledge base context
2. � **Second Priority**: Answer using provided web search results (if available)
3. 🙋 **Third Priority**: Admit you don't know and suggest where to find the information

**Response Format Requirements:**
📱 Use relevant emojis and clear structure
🎯 Start with a clear, direct answer
📚 Cite sources: [MIST Knowledge] or [Web Search] 
⚠️ If uncertain, clearly state limitations

**When You DON'T Have Information:**
Say: "I don't have current information about [specific topic]. For the most accurate and up-to-date information about [topic], I recommend:
• � Contacting MIST directly
• 🌐 Visiting the official MIST website
• � Reaching out to the relevant department"

**Your Knowledge Areas (ONLY if provided in context):**
🏫 **Academics:** CSE, EEE, CE, ME, ARCH, NAME departments
📚 **Programs:** Undergraduate, graduate programs and requirements  
🏢 **Facilities:** Labs, libraries, hostels, medical center
👥 **Services:** Blood bank, tuition, study groups, research
💼 **Career:** Job prospects, industry connections, internships

**Response Structure:**
```
## 🎯 [Direct Answer]

### 📋 Key Information:
• Point 1 [Source: MIST Knowledge/Web Search]
• Point 2 [Source: MIST Knowledge/Web Search]

### ⚠️ Important Notes:
- Important caveats or limitations

### � Additional Help:
- Where to get more information
```

Remember: It's better to say "I don't know" than to provide incorrect information about MIST!
"""
    
    def _beautify_response(self, response: str) -> str:
        """
        Enhanced response formatting with emojis and better structure
        """
        # If response is already well-formatted, return as is
        if "##" in response or "###" in response:
            return response
        
        # Add spacing and formatting improvements
        import re
        
        # Add proper spacing around sentences
        response = re.sub(r'\.(\w)', r'. \1', response)
        response = re.sub(r'\?(\w)', r'? \1', response)
        response = re.sub(r'!(\w)', r'! \1', response)
        
        # If it's a short response, keep it simple but add appropriate emoji
        if len(response) < 200:
            # Add contextual emojis based on content
            if any(word in response.lower() for word in ['computer science', 'cse', 'programming']):
                return f"💻 {response}"
            elif any(word in response.lower() for word in ['admission', 'apply', 'requirement']):
                return f"📝 {response}"
            elif any(word in response.lower() for word in ['mist', 'university', 'institute']):
                return f"🎓 {response}"
            elif any(word in response.lower() for word in ['research', 'project', 'thesis']):
                return f"🔬 {response}"
            elif any(word in response.lower() for word in ['career', 'job', 'placement']):
                return f"💼 {response}"
            else:
                return f"ℹ️ {response}"
        
        # For longer responses, add structure
        lines = response.split('\n')
        formatted_lines = []
        
        for line in lines:
            line = line.strip()
            if not line:
                formatted_lines.append('')
                continue
                
            # Add emojis to key topics
            if any(keyword in line.lower() for keyword in ['computer science', 'cse', 'software']):
                line = f"💻 {line}"
            elif any(keyword in line.lower() for keyword in ['electrical', 'eee', 'electronics']):
                line = f"⚡ {line}"
            elif any(keyword in line.lower() for keyword in ['mechanical', 'me', 'engineering']):
                line = f"⚙️ {line}"
            elif any(keyword in line.lower() for keyword in ['civil', 'ce', 'construction']):
                line = f"🏗️ {line}"
            elif any(keyword in line.lower() for keyword in ['admission', 'requirement', 'apply']):
                line = f"📝 {line}"
            elif any(keyword in line.lower() for keyword in ['research', 'project', 'thesis']):
                line = f"🔬 {line}"
            elif any(keyword in line.lower() for keyword in ['career', 'job', 'placement']):
                line = f"💼 {line}"
            elif any(keyword in line.lower() for keyword in ['facility', 'lab', 'library']):
                line = f"🏢 {line}"
            elif any(keyword in line.lower() for keyword in ['important', 'note', 'remember']):
                line = f"⚠️ {line}"
            elif any(keyword in line.lower() for keyword in ['tip', 'advice', 'suggest']):
                line = f"💡 {line}"
            elif line.endswith(':') or 'benefits' in line.lower() or 'advantages' in line.lower():
                line = f"✨ {line}"
            
            formatted_lines.append(line)
        
        return '\n'.join(formatted_lines)

    def generate_response(self, 
                         message: str, 
                         conversation_history: Optional[List[Dict]] = None,
                         context: Optional[str] = None) -> Dict[str, Any]:
        """
        Generate response using Groq API
        
        Args:
            message: User's input message
            conversation_history: Previous conversation messages
            context: Additional context from RAG system
            
        Returns:
            Dictionary with response and metadata
        """
        try:
            # Build messages array
            messages = [{"role": "system", "content": self._create_system_prompt()}]
            
            # Add context if provided (from RAG system or web search)
            if context:
                # Determine context source
                context_source = "Knowledge Base" if "MIST:" in context else "Web Search"
                
                context_message = f"""**📚 Relevant Information from {context_source}:**

{context}

**🎯 INSTRUCTIONS:**
- Use ONLY the information provided above to answer the user's question
- If the context doesn't fully answer the question, clearly state what information is missing
- Cite your sources using [MIST Knowledge] or [Web Search] tags
- If the context is insufficient, suggest where the user can find complete information
- DO NOT add information not present in the context above"""
                
                messages.append({"role": "system", "content": context_message})
            
            # Add conversation history
            if conversation_history:
                for msg in conversation_history[-10:]:  # Keep last 10 messages for context
                    if msg.get('role') in ['user', 'assistant']:
                        messages.append({
                            "role": msg['role'],
                            "content": msg.get('content', '')
                        })
            
            # Add current user message
            messages.append({"role": "user", "content": message})
            
            # Make API request to Groq
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "model": self.model,
                "messages": messages,
                "max_tokens": 2048,
                "temperature": 0.3,  # Lower temperature for more focused, less creative responses
                "top_p": 0.8,        # Reduced for better consistency
                "stream": False,
                "presence_penalty": 0.1,  # Slight penalty to avoid repetition
                "frequency_penalty": 0.1   # Slight penalty to avoid repetition
            }
            
            response = requests.post(
                self.base_url,
                headers=headers,
                json=payload,
                timeout=30
            )
            
            # Debug: Log response details for troubleshooting
            if response.status_code != 200:
                logger.error(f"Groq API error {response.status_code}: {response.text}")
            
            response.raise_for_status()
            result = response.json()
            
            if 'choices' not in result or not result['choices']:
                raise Exception("No response generated from Groq API")
            
            ai_response = result['choices'][0]['message']['content']
            
            # Beautify the response
            formatted_response = self._beautify_response(ai_response)
            
            return {
                'success': True,
                'response': formatted_response,
                'model': self.model,
                'usage': result.get('usage', {}),
                'context_used': bool(context)
            }
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Groq API request failed: {str(e)}")
            return {
                'success': False,
                'error': f"API request failed: {str(e)}",
                'response': "I'm experiencing technical difficulties. Please try again in a moment."
            }
        except Exception as e:
            logger.error(f"Groq service error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'response': "I encountered an error while processing your request. Please try again."
            }
    
    def analyze_text(self, text: str, analysis_type: str = "general") -> Dict[str, Any]:
        """
        Analyze text for specific purposes (summarization, extraction, etc.)
        
        Args:
            text: Text to analyze
            analysis_type: Type of analysis (general, summarize, extract_keywords, etc.)
            
        Returns:
            Analysis results
        """
        try:
            if analysis_type == "summarize":
                prompt = f"Please provide a concise summary of the following text:\n\n{text}"
            elif analysis_type == "extract_keywords":
                prompt = f"Extract the main keywords and topics from this text:\n\n{text}"
            elif analysis_type == "classify":
                prompt = f"Classify the topic and intent of this text:\n\n{text}"
            else:
                prompt = f"Analyze this text and provide insights:\n\n{text}"
            
            result = self.generate_response(prompt)
            return result
            
        except Exception as e:
            logger.error(f"Text analysis error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'response': "Text analysis failed."
            }
    
    def get_model_info(self) -> Dict[str, Any]:
        """Get information about the current model"""
        return {
            'provider': 'Groq',
            'model': self.model,
            'capabilities': [
                'text_generation',
                'conversation',
                'text_analysis',
                'summarization',
                'question_answering'
            ],
            'max_tokens': 8192,
            'context_window': 32768
        }

# Global service instances
_groq_service = None
_chatbot_groq_service = None

def get_groq_service(use_chatbot_key=False):
    """Get or create Groq service instance"""
    global _groq_service, _chatbot_groq_service
    
    if use_chatbot_key:
        if _chatbot_groq_service is None:
            _chatbot_groq_service = GroqService(use_chatbot_key=True)
        return _chatbot_groq_service
    else:
        if _groq_service is None:
            _groq_service = GroqService(use_chatbot_key=False)
        return _groq_service
