// src/IncidentForm.js

import React, { useState, useEffect, useRef } from 'react';
import { supabase } from './supabase';

export default function IncidentForm({ user }) {
  const [clients, setClients] = useState([]);
  const [clientId, setClientId] = useState('');
  const [category, setCategory] = useState('');
  const [description, setDescription] = useState('');
  const [reflection, setReflection] = useState('');
  const [serious, setSerious] = useState(false);
  const [coStaff, setCoStaff] = useState('');
  const [status, setStatus] = useState('');

  const recognitionRef = useRef(null);

  // 🎙️ Optional Voice-to-Text Support
  function handleVoiceInput(target) {
    if (!('webkitSpeechRecognition' in window)) {
      alert('Raddgreining ekki studd í þessum vafra.');
      return;
    }

    const recognition = new window.webkitSpeechRecognition();
    recognition.lang = 'is-IS';
    recognition.continuous = false;
    recognition.interimResults = false;

    recognition.onresult = function (event) {
      const transcript = event.results[0][0].transcript;
      if (target === 'description') {
        setDescription((prev) => prev + ' ' + transcript);
      } else {
        setReflection((prev) => prev + ' ' + transcript);
      }
    };

    recognition.start();
    recognitionRef.current = recognition;
  }

  // Load clients from Supabase
  useEffect(() => {
    async function loadClients() {
      const { data, error } = await supabase
        .from('clients')
        .select('*')
        .order('label', { ascending: true });
      if (error) {
        console.error('Villa við að sækja íbúa:', error.message);
      } else {
        setClients(data);
      }
    }
    loadClients();
  }, []);

  async function handleSubmit(e) {
    e.preventDefault();
    if (!clientId || !category || !description) {
      setStatus('Vinsamlegast fylltu út nauðsynlega reiti.');
      return;
    }

    const { error } = await supabase.from('incidents').insert({
      client_id: clientId,
      category,
      description,
      reflection,
      serious,
      submitted_by: user.id,
      co_staff: coStaff ? coStaff.split(',').map((s) => s.trim()) : [],
    });

    if (error) {
      setStatus('Villa við innsendingu: ' + error.message);
    } else {
      setStatus('Atvik skráð með góðum árangri.');
      setClientId('');
      setCategory('');
      setDescription('');
      setReflection('');
      setSerious(false);
      setCoStaff('');
    }
  }

  const categories = [
    'Positive Progress',
    'Medical',
    'Behavioral',
    'Safety',
    'Emergency',
    'Other',
  ];

  return (
    <form onSubmit={handleSubmit}>
      <h2>Skrá atvik</h2>

      <label>Íbúi</label>
      <select value={clientId} onChange={(e) => setClientId(e.target.value)}>
        <option value="">Veldu íbúa</option>
        {clients.map((client) => (
          <option key={client.id} value={client.id}>
            {client.label}
          </option>
        ))}
      </select>

      <label>Flokkur</label>
      <select value={category} onChange={(e) => setCategory(e.target.value)}>
        <option value="">Veldu flokk</option>
        {categories.map((cat) => (
          <option key={cat} value={cat}>
            {cat}
          </option>
        ))}
      </select>

      <label>Lýsing</label>
      <textarea
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        placeholder="Hvað gerðist?"
      />
      <button type="button" onClick={() => handleVoiceInput('description')}>
        🎙️ Tala (Lýsing)
      </button>

      <label>Hugleiðing</label>
      <textarea
        value={reflection}
        onChange={(e) => setReflection(e.target.value)}
        placeholder="Hvað hefði mátt fara öðruvísi? Hvernig brást teymið við?"
      />
      <button type="button" onClick={() => handleVoiceInput('reflection')}>
        🎙️ Tala (Hugleiðing)
      </button>

      <label>Samstarfsmenn sem komu að þessu (ef einhverjir)</label>
      <input
        type="text"
        value={coStaff}
        onChange={(e) => setCoStaff(e.target.value)}
        placeholder="Nöfn aðskilin með kommu (t.d. Anna, Björn)"
      />

      <label>
        <input
          type="checkbox"
          checked={serious}
          onChange={(e) => setSerious(e.target.checked)}
        />{' '}
        Alvarlegt atvik
      </label>

      <br />
      <button type="submit">Skrá atvik</button>
      <p>{status}</p>
    </form>
  );
}
