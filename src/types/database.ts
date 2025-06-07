export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      clients: {
        Row: {
          id: string
          name: string | null
          label: string | null
          created_at: string | null
        }
        Insert: {
          id?: string
          name?: string | null
          label?: string | null
          created_at?: string | null
        }
        Update: {
          id?: string
          name?: string | null
          label?: string | null
          created_at?: string | null
        }
        Relationships: []
      }
      incidents: {
        Row: {
          id: string
          client_id: string
          submitted_by: string
          category: string
          description: string
          reflection: string | null
          serious: boolean | null
          co_staff: Json | null
          created_at: string | null
        }
        Insert: {
          id?: string
          client_id: string
          submitted_by: string
          category: string
          description: string
          reflection?: string | null
          serious?: boolean | null
          co_staff?: Json | null
          created_at?: string | null
        }
        Update: {
          id?: string
          client_id?: string
          submitted_by?: string
          category?: string
          description?: string
          reflection?: string | null
          serious?: boolean | null
          co_staff?: Json | null
          created_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "incidents_client_id_fkey"
            columns: ["client_id"]
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incidents_submitted_by_fkey"
            columns: ["submitted_by"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      goals: {
        Row: {
          id: string
          client_id: string
          created_by: string
          title: string
          description: string | null
          status: string | null
          created_at: string | null
        }
        Insert: {
          id?: string
          client_id: string
          created_by: string
          title: string
          description?: string | null
          status?: string | null
          created_at?: string | null
        }
        Update: {
          id?: string
          client_id?: string
          created_by?: string
          title?: string
          description?: string | null
          status?: string | null
          created_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "goals_created_by_fkey"
            columns: ["created_by"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      goal_updates: {
        Row: {
          id: string
          goal_id: string
          created_by: string
          update_text: string
          progress_type: string
          created_at: string | null
        }
        Insert: {
          id?: string
          goal_id: string
          created_by: string
          update_text: string
          progress_type: string
          created_at?: string | null
        }
        Update: {
          id?: string
          goal_id?: string
          created_by?: string
          update_text?: string
          progress_type?: string
          created_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "goal_updates_created_by_fkey"
            columns: ["created_by"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "goal_updates_goal_id_fkey"
            columns: ["goal_id"]
            referencedRelation: "goals"
            referencedColumns: ["id"]
          }
        ]
      }
      role_change_log: {
        Row: {
          id: string
          user_id: string | null
          old_role: string | null
          new_role: string | null
          changed_by: string | null
          changed_at: string | null
        }
        Insert: {
          id?: string
          user_id?: string | null
          old_role?: string | null
          new_role?: string | null
          changed_by?: string | null
          changed_at?: string | null
        }
        Update: {
          id?: string
          user_id?: string | null
          old_role?: string | null
          new_role?: string | null
          changed_by?: string | null
          changed_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "role_change_log_changed_by_fkey"
            columns: ["changed_by"]
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "role_change_log_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      user_profiles: {
        Row: {
          id: string
          full_name: string | null
          role: string
          created_at: string | null
        }
        Insert: {
          id: string
          full_name?: string | null
          role?: string
          created_at?: string | null
        }
        Update: {
          id?: string
          full_name?: string | null
          role?: string
          created_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_profiles_id_fkey"
            columns: ["id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      user_roles: {
        Row: {
          id: string
          role: string
        }
        Insert: {
          id: string
          role?: string
        }
        Update: {
          id?: string
          role?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_id_fkey"
            columns: ["id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      manager_dashboard_stats: {
        Row: {
          incidents_this_week: number | null
          incidents_this_month: number | null
          serious_incidents: number | null
          unique_clients_affected: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      user_role: "employee" | "manager"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}