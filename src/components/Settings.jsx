import React, { useState } from 'react';
import { Dialog } from '@headlessui/react';
import { supabase } from '../supabase';
import { useAuth } from '../hooks/useAuth';
import toast from 'react-hot-toast';

export function Settings({ isOpen, onClose }) {
  const { profile, user, isManager } = useAuth();
  const [role, setRole] = useState(profile?.role || 'employee');
  const [loading, setLoading] = useState(false);

  const handleRoleChange = async (newRole) => {
    // Only managers can change roles
    if (!isManager) {
      toast.error('Only managers can change roles');
      return;
    }

    setLoading(true);
    try {
      const { error } = await supabase
        .from('user_profiles')
        .update({ role: newRole })
        .eq('id', user.id);

      if (error) throw error;

      setRole(newRole);
      toast.success('Role updated successfully');
      
      // Force reload to update navigation and permissions
      window.location.reload();
    } catch (error) {
      toast.error('Failed to update role');
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="mx-auto max-w-sm rounded bg-white p-6 shadow-xl">
          <Dialog.Title className="text-lg font-medium leading-6 text-gray-900 mb-4">
            Settings
          </Dialog.Title>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Role
              </label>
              <select
                value={role}
                onChange={(e) => handleRoleChange(e.target.value)}
                disabled={!isManager || loading}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm disabled:bg-gray-100 disabled:cursor-not-allowed"
              >
                <option value="employee">Employee</option>
                <option value="manager">Manager</option>
              </select>
              {!isManager && (
                <p className="mt-1 text-sm text-gray-500">
                  Only managers can change roles
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <input
                type="email"
                value={user?.email}
                disabled
                className="mt-1 block w-full rounded-md border-gray-300 bg-gray-50 shadow-sm sm:text-sm"
              />
              <p className="mt-1 text-sm text-gray-500">Email cannot be changed</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Full Name
              </label>
              <input
                type="text"
                value={profile?.full_name}
                disabled
                className="mt-1 block w-full rounded-md border-gray-300 bg-gray-50 shadow-sm sm:text-sm"
              />
            </div>
          </div>

          <div className="mt-6 flex justify-end">
            <button
              onClick={onClose}
              className="rounded-md bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
            >
              Close
            </button>
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}