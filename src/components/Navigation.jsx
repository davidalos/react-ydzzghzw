import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { supabase } from '../supabase';
import { Settings } from './Settings';
import { Cog6ToothIcon, Bars3Icon, UserCircleIcon } from '@heroicons/react/24/outline';

export function Navigation() {
  const { profile, isManager } = useAuth();
  const navigate = useNavigate();
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate('/login');
  };

  return (
    <nav className="bg-gradient-to-r from-indigo-600 via-purple-600 to-indigo-600">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          {/* Logo + Links */}
          <div className="flex items-center">
            <button
              className="text-white md:hidden mr-2"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <Bars3Icon className="h-6 w-6" />
            </button>
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
                <Link
                  to="/yfirlit"
                  className="text-white hover:bg-indigo-500 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Yfirlit
                </Link>
              </div>
            </div>
          </div>

          {/* Right Side: User Info + Settings + Logout */}
          <div className="hidden md:block">
            <div className="ml-4 flex items-center space-x-4 md:ml-6">
              <div className="flex items-center space-x-1 text-white text-sm">
                <UserCircleIcon className="h-6 w-6" />
                <div className="flex flex-col items-end">
                  <span>{profile?.full_name}</span>
                  <span className="text-xs opacity-75">
                    {isManager ? '🧑‍💼 Manager' : '👷 Staff'}
                  </span>
                </div>
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

      {mobileMenuOpen && (
        <div className="md:hidden px-2 pt-2 pb-3 space-y-1 bg-indigo-500">
          <Link
            to="/atvik"
            className="block text-white px-3 py-2 rounded-md text-base font-medium"
            onClick={() => setMobileMenuOpen(false)}
          >
            Atvik
          </Link>
          <Link
            to="/markmid"
            className="block text-white px-3 py-2 rounded-md text-base font-medium"
            onClick={() => setMobileMenuOpen(false)}
          >
            Markmið
          </Link>
          <Link
            to="/yfirlit"
            className="block text-white px-3 py-2 rounded-md text-base font-medium"
            onClick={() => setMobileMenuOpen(false)}
          >
            Yfirlit
          </Link>
          <button
            onClick={() => {
              setMobileMenuOpen(false);
              handleLogout();
            }}
            className="block w-full text-left text-white px-3 py-2 rounded-md text-base font-medium"
          >
            Útskrá
          </button>
        </div>
      )}

      {/* Settings Modal */}
      <Settings isOpen={isSettingsOpen} onClose={() => setIsSettingsOpen(false)} />
    </nav>
  );
}
