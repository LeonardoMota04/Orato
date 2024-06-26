//
//  MyTrainingsView.swift
//  Mini04
//
//  Created by Leonardo Mota on 30/03/24.
//

import SwiftUI

struct MyTrainingsView: View {
    @ObservedObject var folderVM: FoldersViewModel
    
    let trainingFilters: [TreinoModel.TrainingFilter] =  TreinoModel.TrainingFilter.allCases
    @State private var selectedFilter: TreinoModel.TrainingFilter = .newerToOlder
    @Binding var filteredTrainings: [TreinoModel]

    @Binding var isShowingModal: Bool
    @State private var selectedFavoriteOption: Bool = false
    @Binding var selectedTrainingIndex: Int?


    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Meus Treinos")
                    .font(.title2)
                    .bold()
                Spacer()
                
                CustomPickerView(selectedSortByOption: $selectedFilter, selectedFavoriteOption: $selectedFavoriteOption)
                    .frame(maxWidth: 220)
                    .padding(4)
                    .background(Color.lightWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .shadow(radius: 2)
            }
            TrainingCellsView(folderVM: folderVM, filteredTrainings: $filteredTrainings, selectedFilter: selectedFilter, selectedFavoriteOption: $selectedFavoriteOption, isShowingModal: $isShowingModal, selectedTrainingIndex: $selectedTrainingIndex)
                

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TrainingCellsView: View {
    @ObservedObject var folderVM: FoldersViewModel
    
    // FILTERS
    @Binding var filteredTrainings: [TreinoModel]
    var selectedFilter: TreinoModel.TrainingFilter?
    @Binding var selectedFavoriteOption: Bool

    @Binding var isShowingModal: Bool
    @Binding var selectedTrainingIndex: Int?

    var body: some View {
        HStack {
            Text("Nº do Treino")
                Spacer()
            Text("Feito em")
                Spacer()
            Image(systemName: "timer")
            Text("Duração")
                Spacer()
        }
        .font(.footnote)
        .padding(.leading, 40)
        .padding(.bottom, 10)
        ScrollView {
            ForEach(Array(filteredTrainings.enumerated()), id: \.element.id) { (index, training) in
                Button {
                    //                    selectedTraining = training
                    selectedTrainingIndex = index
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingModal.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "video.badge.waveform.fill")
                            .foregroundStyle(Color("light_DarkerGreen"))
                        Text(training.nome)
                            .foregroundStyle(Color("light_DarkerGreen"))
                            .bold()
                        
                        Spacer()
                        
                        // Data de criação
                        Text(training.formattedCreationDate())
                            .foregroundStyle(Color("light_DarkerGreen"))
                        Spacer()
                        
                        // Duração do treino
                        Text((training.video?.formattedTime()) ?? "")
                            .foregroundStyle(Color("light_DarkerGreen"))
                        Spacer()
                        
                        Image(systemName: training.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(Color("light_DarkerGreen"))
                            .onTapGesture { training.isFavorite.toggle() }
                            .font(.system(size: 15))
                        
                    }
                    .transition(.scale) // Adiciona a transição de escala

                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(Color.lightWhite)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 15)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    Button("Apagar") {
                        withAnimation {
                            folderVM.deleteTraining(training)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.light)

        .padding(.top, 25)
        // ATUALIZAR A LISTA FILTRADA DE TREINOS
        /// ao abrir, ele atualiza a lista de treinos
        .onAppear {
            withAnimation {
                updateFilteredTrainings()
            }
        }
        /// ao trocar de filtro, ele atualiza a lista de treinos
        .onChange(of: selectedFilter) { _, _ in
            withAnimation {
                updateFilteredTrainings()
            }
        }
        /// ao trocar de pasta ele atualiza a lista de treinos
        .onChange(of: folderVM.folder) { _, _ in
            withAnimation {
                updateFilteredTrainings()
            }
        }
        /// ao adicionar um trieno ele atualiza a lista de treinos
        .onChange(of: folderVM.folder.treinos.count) { _, _ in
            withAnimation {
                updateFilteredTrainings()
            }
        }
        /// ao aplicar o filtro de favoritos, ele atualiza a lista de treinos
        .onChange(of: selectedFavoriteOption) { _, _ in
            withAnimation {
                updateFilteredTrainings()
            }
        }
        
    }
    
    private func updateFilteredTrainings() {
        if selectedFavoriteOption {
            // Se o filtro de favoritos estiver ativado
            switch selectedFilter {
            // Mais recente para mais antigo
            case .newerToOlder:
                filteredTrainings = folderVM.folder.treinos.filter { $0.isFavorite }.sorted(by: { $0.data > $1.data })
        
            // Mais antigo para mais recente
            case .olderToNewer:
                filteredTrainings = folderVM.folder.treinos.filter { $0.isFavorite }.sorted(by: { $0.data < $1.data })
                
            // Mais longo para mais rápido
            case .longerToFaster:
                filteredTrainings = folderVM.folder.treinos.filter { $0.isFavorite }.sorted(by: { ($0.video?.videoTime ?? 0) > ($1.video?.videoTime ?? 0) })
        
            // Mais rápido para mais longo
            case .fasterToLonger:
                filteredTrainings = folderVM.folder.treinos.filter { $0.isFavorite }.sorted(by: { ($0.video?.videoTime ?? 0) < ($1.video?.videoTime ?? 0) })
            
            // Favoritos (essa parte não será executada caso selectedFavoriteOption seja true)
            case .favorites:
                filteredTrainings = folderVM.folder.treinos.filter { $0.isFavorite }
            default:
                break // Caso padrão vazio
            }
        } else {
            // Se o filtro de favoritos estiver desativado, aplicar os filtros padrão
            switch selectedFilter {
            // Mais recente para mais antigo
            case .newerToOlder:
                filteredTrainings = folderVM.folder.treinos.sorted(by: { $0.data > $1.data })
        
            // Mais antigo para mais recente
            case .olderToNewer:
                filteredTrainings = folderVM.folder.treinos.sorted(by: { $0.data < $1.data })
                
            // Mais longo para mais rápido
            case .longerToFaster:
                filteredTrainings = folderVM.folder.treinos.sorted(by: { ($0.video?.videoTime ?? 0) > ($1.video?.videoTime ?? 0) })
        
            // Mais rápido para mais longo
            case .fasterToLonger:
                filteredTrainings = folderVM.folder.treinos.sorted(by: { ($0.video?.videoTime ?? 0) < ($1.video?.videoTime ?? 0) })
            
            // Favoritos (essa parte não será executada caso selectedFavoriteOption seja true)
            case .favorites:
                filteredTrainings = folderVM.folder.treinos.filter { $0.isFavorite }
            default:
                break // Caso padrão vazio
            }
        }
    }
}

struct CustomPickerView: View {

    let trainingFilters: [TreinoModel.TrainingFilter] =  TreinoModel.TrainingFilter.allCases
    @Binding var selectedSortByOption: TreinoModel.TrainingFilter
    @Binding var selectedFavoriteOption: Bool

    var body: some View {
        Menu {
            Section(header: Text("Classificar por")) {
                ForEach(trainingFilters.filter { $0.rawValue != "Favoritos"}, id: \.self) { filter in
                    Button(filter.rawValue) {
                        selectedSortByOption = filter
                    }
                }
            }
            Section(header: Text("Filtrar por")) {
                Toggle(isOn: $selectedFavoriteOption) {
                    Text("Favoritos")
                }
                .toggleStyle(.button)
            }
        } label: {
            Text(selectedSortByOption == .favorites ? "Favoritos" : selectedSortByOption.rawValue)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .menuStyle(.borderlessButton)
        .background {
            RoundedRectangle(cornerRadius: 5)
                .foregroundStyle(.clear)
                .frame(height: 22)
        }
    }
}
