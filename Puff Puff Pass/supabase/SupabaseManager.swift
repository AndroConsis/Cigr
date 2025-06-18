//
//  SupabaseManager.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 18/06/25.
//

import Supabase
import Foundation

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let supabaseUrl = URL(string: "https://oocoexbkvczrfkcytrnv.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vY29leGJrdmN6cmZrY3l0cm52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAwOTI3NzIsImV4cCI6MjA2NTY2ODc3Mn0.uCRdwXxZwLwPz0t-Qpt1o-HldHgjDwX-SeqB5ChaB1Y"

        self.client = SupabaseClient(supabaseURL: supabaseUrl, supabaseKey: supabaseKey)
    }
}
