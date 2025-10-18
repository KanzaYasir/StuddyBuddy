# 📚 StudyBuddy — Your AI-Powered Study Assistant

**StudyBuddy** is your intelligent  **AI chatbot for learning and note-taking** .

It allows you to  **upload documents (PDF, DOCX, PPTX, PPT)** , ask  **questions directly from your files** ,  **take notes** , and even **export your chat sessions** as **PDF or Word** files — all in one place.

---

## 🚀 Features

* 📂 **Multi-File Uploads** — Upload and manage multiple documents (PDF, DOCX, PPTX, PPT).
* 🔍 **Smart Document Q&A** — Ask natural questions based on your uploaded files.
* 💬 **Chat Interface** — Get conversational, context-aware answers.
* 🧠 **AI-Powered Understanding** — Uses **Gemini + Embeddings** for precise, relevant answers.
* ✏️ **Notes System** — Create, edit, and delete personal study notes.
* 📤 **Export Chats** — Download chat conversations as **PDF** or **Word** files.
* ⚡ **Fast Search** — Uses **FAISS** for lightning-fast semantic document search.
* 🔐 **Private & Local** — All processing happens locally; no cloud storage.
* 🖥 **Cross-Platform** — Flutter frontend + FastAPI backend work seamlessly on desktop and web.

---

## 🎯 Use Cases

* 🧑‍🎓 **Students** — Ask questions directly from lecture notes or books.
* 🧑‍🏫 **Teachers** — Generate summaries, questions, or lesson insights.
* 📚 **Researchers** — Search across multiple academic papers easily.
* 🧑‍💼 **Professionals** — Extract insights from reports or presentations.

---

## 🛠️ Tech Stack

### **Frontend**

* **Flutter** — Beautiful and responsive UI
* **Dart** — Efficient and reactive logic handling

### **Backend**

* **FastAPI** — High-performance Python API
* **FAISS** — Vector similarity search engine
* **LangChain** — Text chunking and embedding pipeline
* **Gemini API** — Generates natural language answers
* **PyPDF2** ,  **python-docx** , **python-pptx** — Document text extraction

---

## ⚙️ Installation Guide

### 🧩 1. Clone the Repository

<pre class="overflow-visible!" data-start="2230" data-end="2310"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>git </span><span>clone</span><span> https://github.com/KanzaYasir/studybuddy.git
</span><span>cd</span><span> studybuddy
</span></span></code></div></div></pre>

---

### 🧰 2. Backend Setup (FastAPI)

<pre class="overflow-visible!" data-start="2351" data-end="2501"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>cd</span><span> backend
python -m venv venv
</span><span>source</span><span> venv/bin/activate   </span><span># Mac/Linux</span><span>
venv\Scripts\activate      </span><span># Windows</span><span>
pip install -r requirements.txt
</span></span></code></div></div></pre>

Create a `.env` file inside the `backend/` folder:

<pre class="overflow-visible!" data-start="2554" data-end="2594"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre!"><span><span>GEMINI_API_KEY</span><span>=your_api_key_here
</span></span></code></div></div></pre>

Run the backend server:

<pre class="overflow-visible!" data-start="2620" data-end="2683"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>uvicorn api:app --reload --host 0.0.0.0 --port 8000
</span></span></code></div></div></pre>

✅ Your backend will be live at: [http://localhost:8000](http://localhost:8000)

---

### 💻 3. Frontend Setup (Flutter)

<pre class="overflow-visible!" data-start="2805" data-end="2856"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>cd</span><span> frontend
flutter pub get
flutter run
</span></span></code></div></div></pre>

✅ The app will connect automatically to your FastAPI backend.

---

## 📁 Folder Structure

<pre class="overflow-visible!" data-start="2949" data-end="3350"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre!"><span><span>studybuddy/
│
├── backend/
│   ├── api.py
│   ├── scripts/
│   │   ├── parser.py
│   │   ├── chunker.py
│   │   ├── embedder.py
│   │   ├── vector_store.py
│   │   ├── question_answer.py
│   │   └── gemini_api.py
│   ├── uploads/
│   ├── requirements.txt
│   ├── Procfile
│   └── .</span><span>env</span><span>
│
├── frontend/
│   ├── lib/
│   ├── assets/
│   ├── pubspec.yaml
│   └── (Flutter UI files)
│
└── README.md
</span></span></code></div></div></pre>

---

## 🧠 How It Works

1. **Upload Documents** — PDF, DOCX, PPTX, or PPT.
2. **Chunking** — The text is split into smaller searchable parts.
3. **Embedding** — Each text chunk is transformed into a vector representation.
4. **Indexing** — Stored using FAISS for efficient similarity search.
5. **Ask Questions** — The system retrieves the most relevant sections.
6. **Generate Answers** — Gemini API crafts a human-like response.
7. **Export or Note-Take** — Save the chat or take notes for later review.

---

## 📦 API Endpoints

| Endpoint         | Method              | Description                          |
| ---------------- | ------------------- | ------------------------------------ |
| `/upload`      | POST                | Upload document (PDF/DOCX/PPTX/PPT)  |
| `/files`       | GET                 | List uploaded files                  |
| `/ask`         | POST                | Ask a question about a specific file |
| `/notes`       | GET/POST/PUT/DELETE | Manage notes                         |
| `/export/pdf`  | POST                | Export chat as PDF                   |
| `/export/word` | POST                | Export chat as Word                  |

---

## 🧑‍💻 Development Tips

* Keep your `.env` file **private** — don’t commit it to GitHub.
* Use [Swagger UI](http://localhost:8000/docs) to test endpoints.
* Use **Flutter hot reload** for faster UI development.
* Make sure backend and frontend ports match in configuration.

---

## 🖼️ Screenshots (Optional)

| Upload Files                                   | Chat Interface                                 | Export Notes                                   |
| ---------------------------------------------- | ---------------------------------------------- | ---------------------------------------------- |
| ![1760243147752](image/README/1760243147752.png) | ![1760243242960](image/README/1760243242960.png) | ![1760243303861](image/README/1760243303861.png) |

---

## 🤝 Contributing

We welcome contributions! 💡

1. Fork the repo
2. Create a feature branch (`git checkout -b feature-name`)
3. Commit changes (`git commit -m "Add feature"`)
4. Push to your fork and open a **Pull Request**

---

## 📜 License

MIT License © 2025 [Kanza Yasir](https://github.com/KanzaYasir)

---

## 💬 Support

If you find **StudyBuddy** helpful, please ⭐ the repo and share it!

For feedback, suggestions, or collaboration — reach out at **[kanzayasir9@gmail.com]()**

---

> *“Study smarter, not harder.”* — **StudyBuddy**
