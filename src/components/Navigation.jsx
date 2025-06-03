import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { supabase } from '../supabase';
import { Settings } from './Settings';
import { Cog6ToothIcon } from '@heroicons/react/24/outline';

export function Navigation() {
  const { profile, isManager } = useAuth();
  const navigate = useNavigate();
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate('/login');
  };

  return (
    <nav className="bg-indigo-600">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          {/* Logo + Links */}
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <Link to="/" className="block">
                <img className="h-12 w-auto" src="/og.png" alt="Kópavogsbær" />
              </Link>
            </div>
            <div className="hidden md:block">
              <div className="ml-10 flex items-baseline space-x-4">
                <Link
                  to="/atvik"
                  className="text-white hover:bg-indigo-500 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Atvik
                </Link>
                <Link
                  to="/markmid"
                  className="text-white hover:bg-indigo-500 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Markmið
                </Link>
                {isManager && (
                  <Link
                    to="/yfirlit"
                    className="text-white hover:bg-indigo-500 px-3 py-2 rounded-md text-sm font-medium"
                  >
                    Yfirlit
                  </Link>
                )}
              </div>
            </div>
          </div>

          {/* Right Side: User Info + Settings + Logout */}
          <div className="hidden md:block">
            <div className="ml-4 flex items-center space-x-4 md:ml-6">
              <div className="flex flex-col items-end text-white text-sm">
                <span>{profile?.full_name}</span>
                <span className="text-xs opacity-75">
                  {isManager ? '🧑‍💼 Manager' : '👷 Staff'}
                </span>
              </div>

              <button
                onClick={() => setIsSettingsOpen(true)}
                className="text-white hover:bg-indigo-500 p-2 rounded-md focus:outline-none focus:ring-2 focus:ring-white"
                title="Settings"
              >
                <Cog6ToothIcon className="h-6 w-6" />
              </button>

              <button
                onClick={handleLogout}
                className="text-white hover:bg-indigo-500 px-3 py-2 rounded-md text-sm font-medium"
              >
                Útskrá
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Settings Modal */}
      <Settings isOpen={isSettingsOpen} onClose={() => setIsSettingsOpen(false)} />
    </nav>
  );
}
