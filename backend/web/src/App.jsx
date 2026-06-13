import React, { useEffect, useState } from 'react';
import { supabase } from './supabaseClient';
import axios from 'axios';

export default function App() {
  const [queue, setQueue] = useState([]);
  const backend = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8000';

  async function fetchQueue() {
    const { data, error } = await supabase
      .from('Queue')
      .select('*')
      .eq('Status', 'Waiting')
      .order('Created_at', { ascending: true })
      .limit(200);
    if (error) {
      console.error(error);
      return;
    }
    setQueue(data);
  }

  useEffect(() => {
    fetchQueue();
    const channel = supabase
      .channel('public:Queue')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'Queue' }, () => {
        fetchQueue();
      })
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  async function serveNext() {
    try {
      await axios.post(`${backend}/serve_next`);
      fetchQueue();
    } catch (err) {
      console.error(err);
      alert('Error serving next');
    }
  }

  return (
    <div style={{ padding: 20, fontFamily: 'Arial' }}>
      <h1>QueueLess Admin</h1>
      <button onClick={fetchQueue} style={{ marginRight: 10 }}>Refresh</button>
      <button onClick={serveNext}>Serve Next</button>
      <table style={{ width: '100%', marginTop: 20, borderCollapse: 'collapse' }}>
        <thead>
          <tr>
            <th>Position</th>
            <th>Name</th>
            <th>Phone</th>
            <th>Email</th>
            <th>Joined</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {queue.map((q, i) => (
            <tr key={q.id} style={{ borderTop: '1px solid #eee' }}>
              <td>{i + 1}</td>
              <td>{q.Name}</td>
              <td>{q.Phone}</td>
              <td>{q.Email}</td>
              <td>{new Date(q.Created_at).toLocaleString()}</td>
              <td>{q.Status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
