/*
 * Copyright (c) 2013-2017 ARM Limited. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the License); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * -----------------------------------------------------------------------------
 *
 * Project:     CMSIS-RTOS RTX
 * Title:       Cortex-M4F Exception handlers
 *
 * -----------------------------------------------------------------------------
 */


        .file    "irq_cm4f.S"
        .syntax  unified

        .equ     I_T_RUN_OFS, 20        // osRtxInfo.thread.run offset
        .equ     I_T_CB_OFS,  164       // osRtxInfo.error_handler_callback offset            
        .equ     TCB_SP_OFS,  56        // TCB.SP offset
        .equ     TCB_SF_OFS,  34        // TCB.stack_frame offset
        .equ     SHCSR_ADDR,  0xE000ED24 // Address of System Handler and Control Status Register 
        .equ     CFSR_ADDR,   0xE000ED28 // Address of Configurable Fault Status Register 
        .equ     HFSR_ADDR,   0xE000ED2C // Address of Hard Fault Status Register
        .equ     DFSR_ADDR,   0xE000ED30 // Address of Debug Fault Status Register
        .equ     AFSR_ADDR,   0xE000ED3C // Address of Auxiliary Fault Status Register
        .equ     MMFAR_ADDR,  0xE000ED34 // Address of MemManage Fault Address Register
        .equ     BFAR_ADDR,   0xE000ED38 // Address of Bus Fault Status Register
        .equ     FAULT_TYPE_HARD_FAULT,           0x10
        .equ     FAULT_TYPE_MEMMANAGE_FAULT,      0x20
        .equ     FAULT_TYPE_BUS_FAULT,            0x30
        .equ     FAULT_TYPE_USAGE_FAULT,          0x40
        .equ     FAULT_TYPE_DEBUG_MONITOR,        0x50
    
    
        .section ".rodata"
        .global  irqRtxLib              // Non weak library reference
irqRtxLib:
        .byte    0


        .thumb
        .section ".text"
        .align   2

        .thumb_func
        .type    HardFault_Handler, %function
        .global  HardFault_Handler
        .fnstart
        .cantunwind
HardFault_Handler:
        LDR      R12,=FAULT_TYPE_HARD_FAULT
        B        Fault_Handler

        .fnend
        .size    HardFault_Handler, .-HardFault_Handler

        .thumb_func
        .type    MemManage_Handler, %function
        .global  MemManage_Handler
        .fnstart
        .cantunwind
MemManage_Handler:
        LDR      R12,=FAULT_TYPE_MEMMANAGE_FAULT
        B        Fault_Handler

        .fnend
        .size    MemManage_Handler, .-MemManage_Handler


        .thumb_func
        .type    BusFault_Handler, %function
        .global  BusFault_Handler
        .fnstart
        .cantunwind
BusFault_Handler:
        LDR      R12,=FAULT_TYPE_BUS_FAULT
        B        Fault_Handler

        .fnend
        .size    BusFault_Handler, .-BusFault_Handler
        
        .thumb_func
        .type    UsageFault_Handler, %function
        .global  UsageFault_Handler
        .fnstart
        .cantunwind
UsageFault_Handler:
        LDR      R12,=FAULT_TYPE_USAGE_FAULT
        B        Fault_Handler

        .fnend
        .size    UsageFault_Handler, .-UsageFault_Handler        

        .thumb_func
        .type    Fault_Handler, %function
        .global  Fault_Handler
        .fnstart
        .cantunwind
Fault_Handler:
        TST      LR,#0x4                  // Check EXC_RETURN for bit 2
        ITE      EQ
        MRSEQ    R0,MSP
        MRSNE    R0,PSP
                
        LDR      R1,=osRtxFaultContext     
        LDR      R2,[R0]                  // Capture R0
        STR      R2,[R1],#4
        LDR      R2,[R0,#4]               // Capture R1
        STR      R2,[R1],#4
        LDR      R2,[R0,#8]               // Capture R2
        STR      R2,[R1],#4
        LDR      R2,[R0,#12]              // Capture R3
        STR      R2,[R1],#4
        STMIA    R1!,{R4-R11}             // Capture R4..R11
        LDR      R2,[R0,#16]              // Capture R12
        STR      R2,[R1],#4
        ADD      R1,#4                    // We will capture SP later, so point to LR position in ctx
        LDR      R2,[R0,#20]              // Capture LR
        STR      R2,[R1],#4
        LDR      R2,[R0,#24]              // Capture PC
        STR      R2,[R1],#4
        LDR      R2,[R0,#28]              // Capture xPSR
        STR      R2,[R1],#4
        // Adjust stack pointer to its original value and capture it
        MOV      R3,R0
        TST      LR,#0x10                 // Check for if FP context was saved  
        ITE      EQ
        ADDEQ    R3,#0x68
        ADDNE    R3,#0x20
        TST      R2,#0x200                // Check for if STK was aligned
        ITE      EQ
        ADDEQ    R3,#0x0
        ADDNE    R3,#0x4
        MOV      R4,R1
        SUB      R4,#0x10                 // Set the location of SP
        STR      R3,[R4]                  // Capture the adjusted SP
        MRS      R2,PSP                   // Get PSP           
        STR      R2,[R1],#4
        MRS      R2,MSP                   // Get MSP           
        STR      R2,[R1],#4
        LDR      R0,=CFSR_ADDR            // Capture CFSR
        LDR      R2,[R0]
        STR      R2,[R1],#4
        LDR      R0,=HFSR_ADDR            // Capture HFSR
        LDR      R2,[R0]
        STR      R2,[R1],#4
        LDR      R0,=DFSR_ADDR            // Capture DFSR
        LDR      R2,[R0]
        STR      R2,[R1],#4
        LDR      R0,=AFSR_ADDR            // Capture AFSR
        LDR      R2,[R0]
        STR      R2,[R1],#4
        LDR      R0,=SHCSR_ADDR           // Capture SHCSR
        LDR      R2,[R0]
        STR      R2,[R1],#4
        LDR      R0,=MMFAR_ADDR           // Capture MMFAR
        LDR      R2,[R0]
        STR      R2,[R1],#4
        LDR      R0,=BFAR_ADDR            // Capture BFAR
        LDR      R2,[R0]
        STR      R2,[R1],#4
        LDR      R2,=osRtxInfo+I_T_CB_OFS // Load address of osRtxInfo.error_handler_callback
        LDR      R3,[R2]                  // Load the address of error_handler_callback                
        CMP      R3,#0
        BNE      ErrorHandler_CB                            
        B        .
ErrorHandler_CB: 
        MOV      R0, R12
        LDR      R1, =osRtxFaultContext
        LDR      R2, =osRtxInfo
        BLX      R3
        B        .                        // Just in case we come back here                        

        .fnend
        .size    Fault_Handler, .-Fault_Handler

        .thumb_func
        .type    SVC_Handler, %function
        .global  SVC_Handler
        .fnstart
        .cantunwind
SVC_Handler:

        TST      LR,#0x04               // Determine return stack from EXC_RETURN bit 2
        ITE      EQ
        MRSEQ    R0,MSP                 // Get MSP if return stack is MSP
        MRSNE    R0,PSP                 // Get PSP if return stack is PSP

        LDR      R1,[R0,#24]            // Load saved PC from stack
        LDRB     R1,[R1,#-2]            // Load SVC number
        CBNZ     R1,SVC_User            // Branch if not SVC 0

        PUSH     {R0,LR}                // Save SP and EXC_RETURN
        LDM      R0,{R0-R3,R12}         // Load function parameters and address from stack
        BLX      R12                    // Call service function
        POP      {R12,LR}               // Restore SP and EXC_RETURN
        STM      R12,{R0-R1}            // Store function return values

SVC_Context:
        LDR      R3,=osRtxInfo+I_T_RUN_OFS // Load address of osRtxInfo.run
        LDM      R3,{R1,R2}             // Load osRtxInfo.thread.run: curr & next
        CMP      R1,R2                  // Check if thread switch is required
        IT       EQ
        BXEQ     LR                     // Exit when threads are the same

        CBNZ     R1,SVC_ContextSave     // Branch if running thread is not deleted
        TST      LR,#0x10               // Check if extended stack frame
        BNE      SVC_ContextSwitch
        LDR      R1,=0xE000EF34         // FPCCR Address
        LDR      R0,[R1]                // Load FPCCR
        BIC      R0,R0,#1               // Clear LSPACT (Lazy state)
        STR      R0,[R1]                // Store FPCCR
        B        SVC_ContextSwitch

SVC_ContextSave:
        STMDB    R12!,{R4-R11}          // Save R4..R11
        TST      LR,#0x10               // Check if extended stack frame
        IT       EQ
        VSTMDBEQ R12!,{S16-S31}         //  Save VFP S16.S31
        STR      R12,[R1,#TCB_SP_OFS]   // Store SP
        STRB     LR, [R1,#TCB_SF_OFS]   // Store stack frame information

SVC_ContextSwitch:
        STR      R2,[R3]                // osRtxInfo.thread.run: curr = next

SVC_ContextRestore:
        LDRB     R1,[R2,#TCB_SF_OFS]    // Load stack frame information
        LDR      R0,[R2,#TCB_SP_OFS]    // Load SP
        ORR      LR,R1,#0xFFFFFF00      // Set EXC_RETURN

        TST      LR,#0x10               // Check if extended stack frame
        IT       EQ
        VLDMIAEQ R0!,{S16-S31}          //  Restore VFP S16..S31
        LDMIA    R0!,{R4-R11}           // Restore R4..R11
        MSR      PSP,R0                 // Set PSP

SVC_Exit:
        BX       LR                     // Exit from handler

SVC_User:
        LDR      R2,=osRtxUserSVC       // Load address of SVC table
        LDR      R3,[R2]                // Load SVC maximum number
        CMP      R1,R3                  // Check SVC number range
        BHI      SVC_Exit               // Branch if out of range

        PUSH     {R0,LR}                // Save SP and EXC_RETURN
        LDR      R12,[R2,R1,LSL #2]     // Load address of SVC function
        LDM      R0,{R0-R3}             // Load function parameters from stack
        BLX      R12                    // Call service function
        POP      {R12,LR}               // Restore SP and EXC_RETURN
        STR      R0,[R12]               // Store function return value

        BX       LR                     // Return from handler

        .fnend
        .size    SVC_Handler, .-SVC_Handler


        .thumb_func
        .type    PendSV_Handler, %function
        .global  PendSV_Handler
        .fnstart
        .cantunwind
PendSV_Handler:

        PUSH     {R0,LR}                // Save EXC_RETURN
        BL       osRtxPendSV_Handler    // Call osRtxPendSV_Handler
        POP      {R0,LR}                // Restore EXC_RETURN
        MRS      R12,PSP
        B        SVC_Context

        .fnend
        .size    PendSV_Handler, .-PendSV_Handler


        .thumb_func
        .type    SysTick_Handler, %function
        .global  SysTick_Handler
        .fnstart
        .cantunwind
SysTick_Handler:

        PUSH     {R0,LR}                // Save EXC_RETURN
        BL       osRtxTick_Handler      // Call osRtxTick_Handler
        POP      {R0,LR}                // Restore EXC_RETURN
        MRS      R12,PSP
        B        SVC_Context

        .fnend
        .size    SysTick_Handler, .-SysTick_Handler


        .end
