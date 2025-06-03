import React, { useRef, useState } from 'react';

export default function VoiceTextInput({ value, onChange, placeholder = '', rows = 3 }) {
  const textareaRef = useRef(null);
  const [listening, setListening] = useState(false);

  const handleVoiceInput = () => {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRecognition) {
      alert('Speech recognition not supported in this browser.');
      return;
    }

    const recognition = new SpeechRecognition();
    recognition.lang = 'is-IS';
    recognition.interimResults = false;
    recognition.maxAlternatives = 1;

    recognition.onstart = () => setListening(true);
    recognition.onend = () => setListening(false);
    recognition.onerror = () => setListening(false);

    recognition.onresult = (event) => {
      const transcript = event.results[0][0].transcript;
      onChange({ target: { value: value + ' ' + transcript } });
    };

    recognition.start();
  };

  return (
    <div className="relative">
      <textarea
        ref={textareaRef}
        rows={rows}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 pr-10"
      />
      <button
        type="button"
        onClick={handleVoiceInput}
        className={`absolute top-2 right-2 text-sm px-2 py-1 rounded ${
          listening ? 'bg-red-100 text-red-700' : 'bg-gray-100 text-gray-600'
        }`}
        title="Speak"
      >
        🎙
      </button>
    </div>
  );
}
