package com.example.writeflow.di

import com.example.writeflow.data.DemoLibraryRepository
import com.example.writeflow.data.DemoScanRepository
import com.example.writeflow.domain.LibraryRepository
import com.example.writeflow.domain.ScanRepository
import com.example.writeflow.presentation.viewmodel.WriteFlowViewModel
import org.koin.core.module.dsl.viewModel
import org.koin.dsl.module

val appModule = module {
    single<LibraryRepository> { DemoLibraryRepository() }
    single<ScanRepository> { DemoScanRepository() }
    viewModel { WriteFlowViewModel(scanRepository = get(), libraryRepository = get()) }
}
