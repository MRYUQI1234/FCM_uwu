import { useState, useEffect } from 'react';
import './index.css';

const API_BASE = 'http://localhost:3000/api/dev';

function App() {
  const [tables, setTables] = useState<string[]>([]);
  const [selectedTable, setSelectedTable] = useState<string>('');
  const [tableData, setTableData] = useState<any[]>([]);
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchTables();
  }, []);

  const fetchTables = async () => {
    try {
      const res = await fetch(`${API_BASE}/tables`);
      const data = await res.json();
      if (data.success) {
        setTables(data.data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const loadTable = async (table: string) => {
    setSelectedTable(table);
    setQuery(`SELECT * FROM ${table} LIMIT 100;`);
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/query`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sql: `SELECT * FROM ${table}` }),
      });
      const data = await res.json();
      if (data.success) {
        setTableData(data.data);
      } else {
        alert('Failed to load table: ' + data.error);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const runCustomQuery = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/query`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sql: query }),
      });
      const data = await res.json();
      if (data.success) {
        // If it's a SELECT, we get data, else result
        const resultData = data.data || [data.result];
        setTableData(resultData);
      } else {
        alert('Query error: ' + data.error);
      }
    } catch (e) {
      console.error(e);
      alert('Request error.');
    } finally {
      setLoading(false);
    }
  };

  const deleteRow = async (rowIndex: number) => {
    const row = tableData[rowIndex];
    const keys = Object.keys(row);
    if (keys.length === 0) return;

    // Choose primary key: guess 'id', otherwise first col
    const pk = keys.includes('id') ? 'id' : keys[0];
    const pkValue = row[pk];

    if (!confirm(`Are you sure you want to delete row where ${pk} = ${pkValue}?`)) return;

    setLoading(true);
    try {
      const sql = `DELETE FROM ${selectedTable} WHERE ${pk} = ?`;
      const res = await fetch(`${API_BASE}/query`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sql, params: [pkValue] }),
      });
      const data = await res.json();
      if (data.success) {
        // Reload after delete
        if (selectedTable) {
          loadTable(selectedTable);
        } else {
          runCustomQuery();
        }
      } else {
        alert('Delete failed: ' + data.error);
        setLoading(false);
      }
    } catch (e) {
      console.error(e);
      alert('Delete failed.');
      setLoading(false);
    }
  };

  return (
    <div className="app-container">
      <div className="sidebar">
        <h1>FCM <span>React DB</span></h1>
        <div className="table-list">
          {tables.map(t => (
            <button
              key={t}
              className={`table-item ${selectedTable === t ? 'active' : ''}`}
              onClick={() => loadTable(t)}
            >
              {t}
            </button>
          ))}
        </div>
      </div>

      <div className="main-content">
        <div className="header-controls">
          <input
            type="text"
            className="query-input"
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Write custom SQL query here... e.g., SELECT * FROM users;"
            onKeyDown={e => { if (e.key === 'Enter') runCustomQuery() }}
          />
          <button className="btn-primary" onClick={runCustomQuery}>
            Execute
          </button>
        </div>

        <div className="data-view">
          {loading && (
            <div className="loading-overlay">
              <div className="spinner"></div>
            </div>
          )}

          {!tableData.length && !loading && (
            <div className="empty-state">
              Data will appear here
            </div>
          )}

          {tableData.length > 0 && (
            <table className="data-table">
              <thead>
                <tr>
                  {Object.keys(tableData[0]).map(key => (
                    <th key={key}>{key}</th>
                  ))}
                  {selectedTable && <th>Actions</th>}
                </tr>
              </thead>
              <tbody>
                {tableData.map((row, i) => (
                  <tr key={i}>
                    {Object.keys(row).map(key => (
                      <td key={key}>{String(row[key])}</td>
                    ))}
                    {selectedTable && (
                      <td>
                        <button className="btn-delete" onClick={() => deleteRow(i)}>
                          Delete
                        </button>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;
