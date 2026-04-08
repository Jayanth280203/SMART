import pdfplumber
import docx
import io
import re

class ResumeParser:
    def __init__(self):
        pass

    def extract_text_from_pdf(self, file_bytes):
        text = ""
        with pdfplumber.open(io.BytesIO(file_bytes)) as pdf:
            for page in pdf.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"
        return self._clean_text(text)

    def extract_text_from_docx(self, file_bytes):
        doc = docx.Document(io.BytesIO(file_bytes))
        text = "\n".join([para.text for para in doc.paragraphs])
        return self._clean_text(text)

    def _clean_text(self, text):
        # Remove extra whitespaces
        text = re.sub(r'\s+', ' ', text)
        # Basic cleaning
        text = text.strip()
        return text

    def parse_structured_data(self, text):
        # Basic pattern matching for structured data extraction
        # In a real system, this would be more complex or LLM-aided
        data = {
            "name": self._extract_name(text),
            "email": self._extract_email(text),
            "phone": self._extract_phone(text),
            "education": self._extract_section(text, "Education"),
            "experience": self._extract_section(text, "Experience"),
            "projects": self._extract_section(text, "Projects"),
            "certifications": self._extract_section(text, "Certifications")
        }
        return data

    def _extract_name(self, text):
        # Simple heuristic: first two words in capitalized case
        lines = text.split('\n')
        if lines:
            words = lines[0].split()
            if len(words) >= 2:
                return f"{words[0]} {words[1]}"
        return "Unknown Candidate"

    def _extract_email(self, text):
        email_pattern = r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'
        match = re.search(email_pattern, text)
        return match.group(0) if match else ""

    def _extract_phone(self, text):
        phone_pattern = r'\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'
        match = re.search(phone_pattern, text)
        return match.group(0) if match else ""

    def _extract_section(self, text, section_name):
        # Heuristic to find section content
        pattern = rf"{section_name}(.*?)(?:\n[A-Z][a-z]+:|$)"
        match = re.search(pattern, text, re.IGNORECASE | re.DOTALL)
        return match.group(1).strip() if match else ""
